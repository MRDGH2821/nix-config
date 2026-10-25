import base64
import json
import shlex
from datetime import timedelta

from test_driver.errors import MachineError, RequestedAssertionFailed


def run(server, client, settings, subtest):
    def quote(value):
        return shlex.quote(str(value))

    def sql(statement, database="postgres"):
        return server.succeed(
            "sudo -u postgres psql -X -v ON_ERROR_STOP=1 -At -d "
            + quote(database)
            + " -c "
            + quote(statement)
        ).strip()

    def request(path, *, token=None, method="GET", data=None, basic=False):
        command = [
            "curl",
            "--silent",
            "--show-error",
            "--noproxy",
            "*",
            "--connect-timeout",
            "3",
            "--max-time",
            "15",
            "--resolve",
            f"git.homelab.test:443:{settings['serverAddress']}",
            "--write-out",
            "\\n%{http_code}",
            "--request",
            method,
        ]
        if token:
            command += ["--header", f"Authorization: token {token}"]
        if basic:
            command += ["--user", "integration:public-integration-password"]
        if data is not None:
            command += [
                "--header",
                "Content-Type: application/json",
                "--data",
                json.dumps(data),
            ]
        command += ["https://git.homelab.test/api/v1" + path]
        output = client.succeed(shlex.join(command))
        body, status = output.rsplit("\n", 1)
        return int(status), json.loads(body)

    def check_repository(token):
        status, repository = request("/repos/integration/persisted-repo", token=token)
        assert status == 200 and repository["private"] is True, repository
        status, content = request(
            "/repos/integration/persisted-repo/contents/probe.txt", token=token
        )
        assert status == 200, content
        assert base64.b64decode(content["content"]) == b"homelab-persisted-value\n", (
            content
        )
        status, _ = request("/repos/integration/persisted-repo")
        assert status in (401, 404), (
            f"Private repository exposed without authentication: {status}"
        )
        status, _ = request("/user", token="invalid-public-fixture-token")
        assert status == 401, f"Invalid API token accepted: {status}"

    units = (
        [
            "postgresql.service",
            "authentik-migrate.service",
            "authentik.service",
            "authentik-worker.service",
            "forgejo.service",
            "pangolin.service",
            "gerbil.service",
            "traefik.service",
            "nginx.service",
            "phpfpm-nextcloud.service",
            "pgadmin.service",
            "homepage-dashboard.service",
            "jellyfin.service",
            "ollama.service",
            "mailpit-sandbox.service",
        ]
        + (["searx.service"] if settings["searxEnabled"] else [])
        + settings["redisUnits"]
        + [
            "podman-" + name + ".service"
            for name in settings["containers"]
            if name != "omniroute-web"
        ]
    )

    # These are local application checks, not claims about empty-db Pangolin routes or SSO enrollment.
    health = [
        ("Forgejo", "http://127.0.0.1:4000/api/healthz", ""),
        ("Authentik live", "http://127.0.0.1:9000/-/health/live/", ""),
        ("Authentik ready", "http://127.0.0.1:9000/-/health/ready/", ""),
        ("Pangolin frontend", "http://127.0.0.1:3002/", ""),
        (
            "Pangolin dynamic provider",
            "http://127.0.0.1:3001/api/v1/traefik-config",
            " | jq -e 'type == \"object\"'",
        ),
        ("BentoPDF", "http://127.0.0.1:8090/", ""),
        (
            "Nextcloud",
            "http://127.0.0.1:9200/status.php",
            " --header 'Host: nextcloud.homelab.test' | jq -e '.installed == true and .maintenance == false and .needsDbUpgrade == false'",
        ),
        ("pgAdmin", "http://127.0.0.1:5050/misc/ping", ""),
        ("Homepage", "http://127.0.0.1:7000/", " --header 'Host: homelab.test'"),
        ("Jellyfin", "http://127.0.0.1:8096/health", ""),
        (
            "Ollama",
            "http://127.0.0.1:11434/api/tags",
            " | jq -e '.models | type == \"array\"'",
        ),
        (
            "Honcho API",
            "http://127.0.0.1:8000/openapi.json",
            " | jq -e '.paths | length > 0'",
        ),
        ("Omni Tools", "http://127.0.0.1:3081/", ""),
        ("VERT", "http://127.0.0.1:3080/", ""),
        ("SMTP fixture", "http://127.0.0.1:8025/livez", ""),
    ] + (
        [("SearxNG", "http://127.0.0.1:7100/", "")] if settings["searxEnabled"] else []
    )

    def check_stack():
        for unit in units:
            server.wait_for_unit(unit, timeout=timedelta(seconds=300))
        server.wait_for_open_port(3004, timeout=timedelta(seconds=180))
        server.succeed("ip link show wg0")
        for name, url, assertion in health:
            with subtest(name + " responds"):
                server.wait_until_succeeds(
                    "curl --noproxy '*' -fsS --connect-timeout 3 --max-time 10 "
                    + quote(url)
                    + assertion,
                    timeout=timedelta(seconds=180),
                )
        omniroute_id = server.succeed(
            "podman inspect --format '{{.Id}}' omniroute-web"
        ).strip()
        failed = server.succeed(
            "systemctl --failed --no-legend --plain --output=json "
            "| jq -r '.[].unit' "
            + "| grep -v -E "
            + quote(
                f"^(linkwarden|linkwarden-worker|podman-omniroute-web|{omniroute_id}-.*)\\.service$"
            )
            + " || true"
        ).strip()
        assert failed == "", failed

    def check_migration():
        migration = server.get_unit_info("podman-honcho-memory-migrate.service")
        assert (
            migration["Result"] == "success" and migration["ExecMainStatus"] == "0"
        ), migration
        finished = int(migration["ExecMainExitTimestampMonotonic"])
        assert finished > 0, migration
        for unit in (
            "podman-honcho-memory-api.service",
            "podman-honcho-memory-deriver.service",
        ):
            info = server.get_unit_info(unit)
            assert int(info["ExecMainStartTimestampMonotonic"]) >= finished, (
                unit,
                migration,
                info,
            )
        assert sql("SELECT count(*) FROM alembic_version", "honcho") == "1"
        # Use the application's socket connection and role, never postgres privileges.
        vector = server.succeed(
            "psql -X -w -v ON_ERROR_STOP=1 -At -h /run/postgresql -U honcho -d honcho -c "
            + quote(
                "SELECT current_user, rolsuper, '[1,2,3]'::vector <-> '[1,2,3]'::vector "
                "FROM pg_roles WHERE rolname = current_user"
            )
        ).strip()
        assert vector == "honcho|f|0", vector
        assert (
            int(
                sql(
                    "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'",
                    "honcho",
                )
            )
            > 1
        )

    def check_isolation():
        for machine in (server, client):
            # Numeric addresses avoid treating a DNS failure as egress isolation.
            machine.fail("nc -z -w 2 1.1.1.1 443")
            machine.fail("nc -z -w 2 10.0.2.2 22")
            machine.fail("nc -z -w 2 10.0.2.2 80")
        client.succeed("nc -z -w 3 server 443")
        # Production intentionally exposes 5432; assert the real policy, not fictional privacy.
        client.succeed("nc -z -w 3 server 5432")
        client.fail(
            "PGCONNECT_TIMEOUT=3 psql -w -h server -U postgres -d postgres -c 'SELECT 1'"
        )
        client.fail("nc -z -w 2 server 4000")
        client.fail("nc -z -w 2 server 8000")
        mounts = set(
            server.succeed("findmnt -rn -t 9p,virtiofs -o TARGET").splitlines()
        )
        assert mounts <= {"/nix/.ro-store", "/tmp/shared", "/tmp/xchg"}, mounts

    server.start(allow_reboot=True)
    client.start()
    try:
        with subtest("full safe stack starts, without enabling disabled applications"):
            check_stack()
            check_migration()
            images = json.loads(server.succeed("cat /etc/homelab-test/images.json"))
            for name, fixture in images.items():
                image_id = server.succeed(
                    "podman image inspect --format '{{.Id}}' " + quote(fixture["image"])
                ).strip()
                assert image_id.removeprefix("sha256:") == fixture[
                    "imageId"
                ].removeprefix("sha256:"), (name, image_id, fixture)
                if name != "honcho-memory-migrate":
                    used_id = server.succeed(
                        "podman inspect --format '{{.Image}}' " + quote(name)
                    ).strip()
                    assert used_id.removeprefix("sha256:") == image_id.removeprefix(
                        "sha256:"
                    ), name
        with subtest("isolated network and effective client firewall policy"):
            check_isolation()
        with subtest("real PostgreSQL write, configured full backup, isolated restore"):
            sql("CREATE DATABASE integration_workflow")
            sql(
                "CREATE TABLE probe (value text NOT NULL); INSERT INTO probe VALUES ('homelab-persisted-value')",
                "integration_workflow",
            )
            assert (
                sql("SELECT value FROM probe", "integration_workflow")
                == "homelab-persisted-value"
            )
            server.succeed("timeout 180 systemctl start postgresqlBackup.service")
            server.succeed("gzip -t " + quote(settings["backup"]))
            # Never replay pg_dumpall over running application databases.
            restored = server.succeed(
                "sudo -u postgres bash -c "
                + quote(
                    f"""
set -euo pipefail
export PATH={quote(settings["postgresqlPackage"] + "/bin")}:$PATH
restore=$(mktemp -d /tmp/homelab-restore.XXXXXX)
trap 'if test -f "$restore/data/postmaster.pid"; then pg_ctl -D "$restore/data" -m immediate -w stop >/dev/null; fi; rm -rf "$restore"' EXIT
mkdir "$restore/socket"
initdb -D "$restore/data" --username=integration_restore_admin --auth=trust >/dev/null
export PGHOST="$restore/socket" PGPORT=5433 PGUSER=integration_restore_admin
pg_ctl -D "$restore/data" -l "$restore/postgresql.log" -o "-c listen_addresses='' -c unix_socket_directories=$PGHOST -p $PGPORT" -w start >/dev/null
gzip -cd {quote(settings["backup"])} | psql -X -v ON_ERROR_STOP=1 -d postgres >/dev/null
psql -X -v ON_ERROR_STOP=1 -At -d integration_workflow -c 'SELECT value FROM probe'
"""
                )
            ).strip()
            assert restored == "homelab-persisted-value", restored
        with subtest(
            "Forgejo user, private repository, and real API authentication through fixture Traefik"
        ):
            forgejo = settings["forgejo"]
            admin = (
                "GITEA_WORK_DIR="
                + quote(forgejo["work"])
                + " "
                + quote(forgejo["executable"])
                + " admin user create --username integration --password public-integration-password"
                + " --email integration@homelab.test --must-change-password=false"
            )
            server.succeed(
                "su -s /bin/sh " + quote(forgejo["user"]) + " -c " + quote(admin)
            )
            status, result = request(
                "/users/integration/tokens",
                method="POST",
                basic=True,
                data={"name": "integration", "scopes": ["all"]},
            )
            assert status == 201, result
            token = result["sha1"]
            status, result = request(
                "/user/repos",
                token=token,
                method="POST",
                data={"name": "persisted-repo", "private": True, "auto_init": True},
            )
            assert status == 201, result
            status, result = request(
                "/repos/integration/persisted-repo/contents/probe.txt",
                token=token,
                method="POST",
                data={
                    "content": base64.b64encode(b"homelab-persisted-value\n").decode(),
                    "message": "Persist integration value",
                },
            )
            assert status == 201, result
            check_repository(token)
        with subtest("failed real Honcho migration blocks both dependents"):
            dependents = (
                "podman-honcho-memory-api.service",
                "podman-honcho-memory-deriver.service",
            )
            server.succeed(
                "systemctl stop "
                + " ".join(dependents)
                + " podman-honcho-memory-migrate.service"
            )
            previous = {
                unit: server.get_unit_info(unit)["ExecMainStartTimestampMonotonic"]
                for unit in dependents
            }
            sql("ALTER DATABASE honcho ALLOW_CONNECTIONS false")
            try:
                sql(
                    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='honcho'"
                )
                status, output = server.execute(
                    "timeout 120 systemctl start " + " ".join(dependents)
                )
                assert status not in (0, 124), output
                failed = server.get_unit_info("podman-honcho-memory-migrate.service")
                assert (
                    failed["Result"] == "exit-code"
                    and int(failed["ExecMainStatus"]) != 0
                ), failed
                for unit in dependents:
                    info = server.get_unit_info(unit)
                    assert info["ActiveState"] in ("inactive", "failed"), (unit, info)
                    assert info["ExecMainStartTimestampMonotonic"] == previous[unit], (
                        unit,
                        info,
                    )
            finally:
                sql("ALTER DATABASE honcho ALLOW_CONNECTIONS true")
            server.succeed("systemctl reset-failed")
            server.succeed("timeout 180 systemctl start " + " ".join(dependents))
            check_migration()
        with subtest("reboot persists actual database and repository values"):
            old_boot = server.succeed("cat /proc/sys/kernel/random/boot_id").strip()
            server.reboot()
            server.wait_for_unit("multi-user.target", timeout=timedelta(seconds=300))
            assert (
                server.succeed("cat /proc/sys/kernel/random/boot_id").strip()
                != old_boot
            )
            check_stack()
            check_migration()
            check_isolation()
            assert (
                sql("SELECT value FROM probe", "integration_workflow")
                == "homelab-persisted-value"
            )
            check_repository(token)
        with subtest("prebuilt candidate activation inside the guest preserves data"):
            candidate = server.succeed(
                "readlink -f /run/current-system/specialisation/integration-candidate"
            ).strip()
            server.succeed(
                "timeout 180 "
                + quote(candidate + "/bin/switch-to-configuration")
                + " test"
            )
            assert server.succeed("cat /etc/homelab-candidate").strip() == "candidate"
            assert (
                server.succeed("readlink -f /run/current-system").strip() == candidate
            )
            check_stack()
            check_isolation()
            assert (
                sql("SELECT value FROM probe", "integration_workflow")
                == "homelab-persisted-value"
            )
            check_repository(token)
    finally:
        # Keep the root cause in the driver log even when the first startup assertion fails.
        for diagnostic in (
            "systemctl --failed --no-pager; ss --listening --numeric --tcp --udp --processes; podman ps -a",
            "journalctl -b --no-pager -n 250 "
            + " ".join("-u " + quote(unit) for unit in units),
        ):
            try:
                print(server.execute(diagnostic, timeout=timedelta(seconds=30))[1])
            except (
                MachineError,
                RequestedAssertionFailed,
                OSError,
                RuntimeError,
                EOFError,
            ) as error:
                print(f"Diagnostics unavailable: {error}")

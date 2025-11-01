import os
import json


def _env_bool(name, default=False):
    v = os.environ.get(name)
    if v is None:
        return default
    return str(v).lower() in ("1", "true", "yes", "on")


def _env_list(name, default=None, sep=","):
    v = os.environ.get(name)
    if v is None:
        return default or []
    return [s.strip() for s in v.split(sep) if s.strip()]


# AUTHENTICATION_SOURCES: comma-separated env var, defaulting to ["oauth2","internal"]
AUTHENTICATION_SOURCES = _env_list(
    "AUTHENTICATION_SOURCES", default=["oauth2", "internal"]
)

# OAUTH2_AUTO_CREATE_USER: boolean env var
OAUTH2_AUTO_CREATE_USER = _env_bool("OAUTH2_AUTO_CREATE_USER", default=True)

# Full JSON override for OAUTH2_CONFIG (useful to provide multiple providers)
# Example: export OAUTH2_CONFIG_JSON='[{"OAUTH2_NAME":"authentik", ...}]'
if os.environ.get("OAUTH2_CONFIG_JSON"):
    try:
        OAUTH2_CONFIG = json.loads(os.environ["OAUTH2_CONFIG_JSON"])
    except Exception:
        # Fallback to single-provider defaults if JSON parse fails
        OAUTH2_CONFIG = None
else:
    OAUTH2_CONFIG = None


if OAUTH2_CONFIG is None:
    # Read individual provider values from environment with sensible defaults
    OAUTH2_NAME = os.environ.get("OAUTH2_NAME", "authentik")
    OAUTH2_CONFIG = [
        {
            "OAUTH2_NAME": OAUTH2_NAME,
            "OAUTH2_DISPLAY_NAME": os.environ.get("OAUTH2_DISPLAY_NAME", OAUTH2_NAME),
            "OAUTH2_CLIENT_ID": os.environ.get(
                "OAUTH2_CLIENT_ID", "<Client ID from authentik>"
            ),
            "OAUTH2_CLIENT_SECRET": os.environ.get(
                "OAUTH2_CLIENT_SECRET", "<Client secret from authentik>"
            ),
            "OAUTH2_TOKEN_URL": os.environ.get(
                "OAUTH2_TOKEN_URL", "https://authentik.company/application/o/token/"
            ),
            "OAUTH2_AUTHORIZATION_URL": os.environ.get(
                "OAUTH2_AUTHORIZATION_URL",
                "https://authentik.company/application/o/authorize/",
            ),
            "OAUTH2_API_BASE_URL": os.environ.get(
                "OAUTH2_API_BASE_URL", "https://authentik.company/"
            ),
            "OAUTH2_USERINFO_ENDPOINT": os.environ.get(
                "OAUTH2_USERINFO_ENDPOINT",
                "https://authentik.company/application/o/userinfo/",
            ),
            "OAUTH2_SERVER_METADATA_URL": os.environ.get(
                "OAUTH2_SERVER_METADATA_URL",
                "https://authentik.company/application/o/<application_slug>/.well-known/openid-configuration",
            ),
            "OAUTH2_SCOPE": os.environ.get("OAUTH2_SCOPE", "openid email profile"),
            "OAUTH2_ICON": os.environ.get("OAUTH2_ICON", "fa-key"),
            "OAUTH2_BUTTON_COLOR": os.environ.get("OAUTH2_BUTTON_COLOR", "#000000"),
        }
    ]

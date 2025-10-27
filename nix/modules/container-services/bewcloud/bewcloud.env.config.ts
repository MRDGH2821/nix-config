import { Config, OptionalApp, PartialDeep } from "./lib/types.ts";
/** Check the Config type for all the possible options and instructions. */
function requireValue<T>(value: T | undefined, key: string): T {
  if (value === undefined || value === "") {
    throw new Error(`Environment variable ${key} is required but not set`);
  }
  return value;
}

function getEnvString(key: string, defaultValue: string): string {
  return Deno.env.get(key) ?? defaultValue;
}

function getEnvBoolean(key: string, defaultValue: boolean): boolean {
  const value = Deno.env.get(key);
  if (value === undefined) return defaultValue;
  return value.toLowerCase() === "true" || value === "1";
}

function getEnvNumber(key: string, defaultValue: number): number {
  const value = Deno.env.get(key);
  if (value === undefined) return defaultValue;
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? defaultValue : parsed;
}

function getEnvStringArray(key: string, defaultValue: string[]): string[] {
  const value = Deno.env.get(key);
  if (value === undefined) return defaultValue;
  return value
    .split(",")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}
const config: PartialDeep<Config> = {
  auth: {
    baseUrl: getEnvString("BEWCLOUD_AUTH_BASE_URL", "http://localhost:8000"),
    allowSignups: getEnvBoolean("BEWCLOUD_AUTH_ALLOW_SIGNUPS", false),
    enableEmailVerification: getEnvBoolean(
      "BEWCLOUD_AUTH_ENABLE_EMAIL_VERIFICATION",
      false
    ),
    enableForeverSignup: getEnvBoolean(
      "BEWCLOUD_AUTH_ENABLE_FOREVER_SIGNUP",
      true
    ),
    enableMultiFactor: getEnvBoolean(
      "BEWCLOUD_AUTH_ENABLE_MULTI_FACTOR",
      false
    ),
    allowedCookieDomains: getEnvStringArray(
      "BEWCLOUD_AUTH_ALLOWED_COOKIE_DOMAINS",
      []
    ),
    skipCookieDomainSecurity: getEnvBoolean(
      "BEWCLOUD_AUTH_SKIP_COOKIE_DOMAIN_SECURITY",
      false
    ),
    enableSingleSignOn: getEnvBoolean(
      "BEWCLOUD_AUTH_ENABLE_SINGLE_SIGN_ON",
      false
    ),
    singleSignOnUrl: getEnvString("BEWCLOUD_AUTH_SINGLE_SIGN_ON_URL", ""),
    singleSignOnEmailAttribute: getEnvString(
      "BEWCLOUD_AUTH_SINGLE_SIGN_ON_EMAIL_ATTRIBUTE",
      "email"
    ),
    singleSignOnScopes: getEnvStringArray(
      "BEWCLOUD_AUTH_SINGLE_SIGN_ON_SCOPES",
      ["openid", "email"]
    ),
  },
  files: {
    rootPath: getEnvString("BEWCLOUD_FILES_ROOT_PATH", "data-files"),
    allowPublicSharing: getEnvBoolean(
      "BEWCLOUD_FILES_ALLOW_PUBLIC_SHARING",
      false
    ),
  },
  core: {
    enabledApps: getEnvStringArray("BEWCLOUD_CORE_ENABLED_APPS", [
      "news",
      "notes",
      "photos",
      "expenses",
    ]) as OptionalApp[],
  },
  visuals: {
    title: getEnvString("BEWCLOUD_VISUALS_TITLE", ""),
    description: getEnvString("BEWCLOUD_VISUALS_DESCRIPTION", ""),
    helpEmail: getEnvString("BEWCLOUD_VISUALS_HELP_EMAIL", "help@bewcloud.com"),
  },
  email: {
    from: getEnvString("BEWCLOUD_EMAIL_FROM", "help@bewcloud.com"),
    host: getEnvString("BEWCLOUD_EMAIL_HOST", "localhost"),
    port: getEnvNumber("BEWCLOUD_EMAIL_PORT", 465),
  },
  contacts: {
    enableCardDavServer: getEnvBoolean(
      "BEWCLOUD_CONTACTS_ENABLE_CARDDAV_SERVER",
      true
    ),
    cardDavUrl: getEnvString(
      "BEWCLOUD_CONTACTS_CARDDAV_URL",
      "http://127.0.0.1:5232"
    ),
  },
  calendar: {
    enableCalDavServer: getEnvBoolean(
      "BEWCLOUD_CALENDAR_ENABLE_CALDAV_SERVER",
      true
    ),
    calDavUrl: getEnvString(
      "BEWCLOUD_CALENDAR_CALDAV_URL",
      "http://127.0.0.1:5232"
    ),
  },
};

export default config;

{config}: let
  domain = config.networking.baseDomain;
in {
  # Construct a subdomain from a prefix and the base domain
  # Usage: lib.networking.mkSubdomain "api" -> "api.your-domain.com"
  mkSubdomain = subdomain: "${subdomain}.${domain}";
  # Create a full URL with subdomain and protocol (defaults to HTTPS)
  # Usage: lib.networking.mkUrl "api" -> "https://api.your-domain.com"
  # Usage: lib.networking.mkUrl "app" false -> "http://app.your-domain.com"
  mkUrl = subdomain: secure: let
    protocol =
      if secure
      then "https"
      else "http";
  in "${protocol}://${subdomain}.${domain}";
}

{config}: {
  # Construct a subdomain from a prefix and the base domain
  # Usage: lib.networking.mkSubdomain "api" -> "api.your-domain.com"
  mkSubdomain = subdomain: "${subdomain}.${config.networking.baseDomain}";

  # Create a full URL with subdomain and protocol (defaults to HTTPS)
  # Usage: lib.networking.mkUrl "api" -> "https://api.your-domain.com"
  # Usage: lib.networking.mkUrl "app" false -> "http://app.your-domain.com"
  mkUrl = subdomain: secure: let
    isSecure =
      if secure == null
      then true
      else secure;
  in
    if isSecure
    then "https://${subdomain}.${config.networking.baseDomain}"
    else "http://${subdomain}.${config.networking.baseDomain}";
}

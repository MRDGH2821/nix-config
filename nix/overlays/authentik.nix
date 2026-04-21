final: prev: {
  authentik = prev.authentik.overrideAttrs (oldAttrs: {
    vendorHash = "sha256-8ChmJNFk8p/HSJQFCs9WZG4QynpIdymQo4t4zUTzBOk=";
  });
}

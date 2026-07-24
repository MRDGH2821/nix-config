{
  inputs ? {},
  lib,
  ...
}: let
  mylib = import ../../lib/auto-import.nix {inherit lib;};
  mylibFor = args: import ../../lib/default.nix ({inherit inputs;} // args);
in {
  _module.args = {inherit mylib mylibFor;};
}

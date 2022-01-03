# This is used in CI to mask the building of packages with very large closures,
# hopefully allowing GitHub to build a subset of the system drv

final: prev:
let
  maskedPkgs = [
    "signal-desktop"
    "element-desktop"
    "thunderbird"
    "firefox-bin"
    "zoom-us"
    "discord"
  ];
  inherit (prev.lib) listToAttrs makeOverridable nameValuePair;
  nullDrv = final.callPackage
    ({ runCommand, ... }:
      runCommand "dummy" { } ''
        mkdir -p $out/{bin,lib}
        echo "dummy" > $out/bin/dummy
        echo "dummy" > $out/lib/dummy
      '')
    { };

  dummyOverrides = listToAttrs (map (p: nameValuePair p nullDrv) maskedPkgs);
in
dummyOverrides

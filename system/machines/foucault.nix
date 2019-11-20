{ config, pkgs, ... }: {
  imports = [
    ../combo/core.nix
    ../combo/dev.nix
    ../combo/graphical.nix
    ../combo/wayland.nix
    ../combo/thinkpad_p1.nix
  ];

  networking.hostName = "foucault";

  time.timeZone = "America/Los_Angeles";
}

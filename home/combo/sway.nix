{ pkgs, ... }: {
  imports = [
    ../modules/mako.nix
    ../modules/sway.nix
    ../modules/swaylock.nix
    ../modules/waybar.nix
  ];
}

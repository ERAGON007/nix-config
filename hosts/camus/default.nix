{ config, nixos-hardware, ... }:
{
  imports = [
    nixos-hardware.common-pc-ssd

    ../../core

    ../../hardware/rpi4.nix
    ../../hardware/nixos-aarch64-builder
    ../../hardware/no-mitigations.nix

    ../../users/bemeurer
  ];

  console.keyMap = "us";

  fileSystems.music = {
    device = "/dev/sda1";
    mountPoint = "/home/bemeurer/music";
    options = [ "default" "noauto" "uid=8888" "gid=8888" ];
  };

  networking = {
    hostName = "camus";
    wireless.iwd.enable = true;
  };

  nix.gc = {
    automatic = true;
    options = "-d";
  };

  systemd.network = {
    networks = {
      eth = {
        DHCP = "yes";
        matchConfig.MACAddress = "e4:5f:01:2a:4e:88";
      };
      wlan = {
        DHCP = "yes";
        matchConfig.MACAddress = "e4:5f:01:2a:4e:89";
      };
    };
    wait-online.anyInterface = true;
  };

  time.timeZone = "America/Los_Angeles";

  age.secrets.rootPassword.file = ./password.age;
  users.users.root.passwordFile = config.age.secrets.rootPassword.path;

  swapDevices = [{ device = "/swap"; size = 16384; }];
}

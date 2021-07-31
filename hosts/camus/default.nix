{ lib, ... }:
{
  imports = [
    ../../core

    ../../hardware/rpi4.nix

    ../../users/bemeurer
  ];

  boot = {
    loader = {
      generic-extlinux-compatible.enable = lib.mkForce false;
      raspberryPi = {
        enable = true;
        firmwareConfig = ''
          dtparam=i2c_arm=on
          dtoverlay=i2c-rtc,ds3231
          dtoverlay=rpi-poe
          dtoverlay=dwc2,dr_mode=host
        '';
        version = 4;
      };
    };
    kernelParams = [ "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0" ];
  };

  fileSystems = lib.mkForce {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  networking = {
    hostName = "camus";
    wireless.iwd.enable = true;
  };

  nix.gc = {
    automatic = true;
    options = "-d";
  };

  systemd.network.networks = {
    eth = {
      DHCP = "yes";
      matchConfig.MACAddress = "e4:5f:01:2a:4e:88";
    };
    wifi = {
      DHCP = "yes";
      matchConfig.MACAddress = "e4:5f:01:2a:4e:89";
    };
  };

  systemd.services.unbound.after = [ "chronyd.service" ];

  time.timeZone = "America/Los_Angeles";

  # sops.secrets.root-password.sopsFile = ./root-password.yaml;
  # users.users.root.passwordFile = config.sops.secrets.root-password.path;
}

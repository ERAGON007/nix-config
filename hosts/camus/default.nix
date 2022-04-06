{ config, lib, ... }:
{
  imports = [
    ../../core

    ../../hardware/rpi4.nix
    ../../hardware/no-mitigations.nix

    ../../users/bemeurer
  ];

  boot = {
    initrd.availableKernelModules = [ "nvme" ];
    loader = {
      generic-extlinux-compatible.enable = lib.mkForce false;
      raspberryPi = {
        enable = true;
        firmwareConfig = ''
          uart_2ndstage=1
          dtoverlay=disable-bt

          dtoverlay=dwc2,dr_mode=host

          dtparam=i2c_arm=on
          dtoverlay=rpi-poe-plus
          dtparam=poe_fan_temp0=50000
          dtparam=poe_fan_temp1=60000
          dtparam=poe_fan_temp2=70000
          dtparam=poe_fan_temp3=80000
        '';
        version = 4;
      };
    };
    kernelParams = [ "earlycon=pl011,mmio32,0xfe201000" "console=ttyAMA0,115200" ];
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

  networking.hostName = "camus";

  nix.gc = {
    automatic = true;
    options = "-d";
  };

  systemd.network.networks.eth = {
    DHCP = "yes";
    matchConfig.MACAddress = "e4:5f:01:2a:4e:88";
  };

  time.timeZone = "America/Los_Angeles";

  age.secrets.rootPassword.file = ./password.age;
  users.users.root.passwordFile = config.age.secrets.rootPassword.path;
}

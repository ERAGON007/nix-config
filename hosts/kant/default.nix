{ config, lib, modulesPath, pkgs, ... }: {
  imports = [
    ../../core

    ../../users/bemeurer

    (modulesPath + "/profiles/qemu-guest.nix")
    # (modulesPath + "/profiles/hardened.nix")
  ];

  boot = {
    cleanTmpDir = true;
    initrd.kernelModules = [ "nvme" ];
    loader.grub.device = "/dev/vda";
  };

  environment.memoryAllocator.provider = "libc";

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  home-manager.users.bemeurer = {
    home.packages = with pkgs; [ weechat ];
  };

  networking = {
    defaultGateway = "143.198.224.1";
    defaultGateway6 = "2604:a880:4:1d0::1";
    dhcpcd.enable = false;
    hostId = "4a8f5793";
    hostName = "kant";
    useNetworkd = lib.mkForce false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces.eth0 = {
      ipv4 = {
        routes = [{ address = "143.198.224.1"; prefixLength = 32; }];
        addresses = [
          { address = "143.198.230.205"; prefixLength = 20; }
          { address = "10.48.0.5"; prefixLength = 16; }
        ];
      };
      ipv6 = {
        addresses = [
          { address = "2604:a880:4:1d0::208:7000"; prefixLength = 64; }
          { address = "fe80::1c8c:8eff:fe5b:f5a6"; prefixLength = 64; }
        ];
        routes = [{ address = "2604:a880:4:1d0::1"; prefixLength = 128; }];
      };
    };
  };

  nix = {
    gc = {
      automatic = true;
      options = "-d";
    };
    settings.max-jobs = 1;
  };

  age.secrets.kantDdclient.file = ./ddclient.age;
  services.ddclient.configFile = config.age.secrets.kantDdclient.path;
  services.ddclient.enable = true;

  services = {
    do-agent.enable = true;
    sshguard.enable = true;
    udev.extraRules = ''
      ATTR{address}=="1e:8c:8e:5b:f5:a6", NAME="eth0"
      ATTR{address}=="86:8b:72:3a:08:e6", NAME="eth1"
    '';
  };

  time.timeZone = "America/Los_Angeles";

  age.secrets.rootPassword.file = ./password.age;
  users.users.root.passwordFile = config.age.secrets.rootPassword.path;
}

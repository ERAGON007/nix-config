{ config, pkgs, ... }: {
  imports = [
    ../../core

    ../../dev

    ../../hardware/efi.nix
    ../../hardware/nouveau.nix
    ../../hardware/zfs.nix

    ../../users/bemeurer

    ./pihole.nix
    ./prometheus.nix
    ./samba.nix
    ./state.nix
    ./unbound.nix
  ];

  boot = {
    blacklistedKernelModules = [ "snd_hda_intel" "amd64_edac_mod" "sp5100_tco" ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "sd_mod" ];
    kernelModules = [ "kvm-amd" ];
    kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;
    tmpOnTmpfs = true;
    zfs = {
      extraPools = [ "tank" ];
      requestEncryptionCredentials = false;
    };
  };

  console = {
    font = "ter-v14n";
    keyMap = "us";
    packages = with pkgs; [ terminus_font ];
  };

  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver 1.1.1.1
    options edns0
  '';

  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "noatime" "size=20%" "mode=755" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/E954-11BC";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/b192a21f-08ae-4ce9-ac41-053854fc52c9";
      fsType = "xfs";
      neededForBoot = true;
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    pulseaudio.enable = false;
  };

  home-manager.users.bemeurer = {
    imports = [
      ../../users/bemeurer/music
    ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ 3000 20 21 ]; # grafana
      allowedUDPPorts = [ 123 ]; # chronyd
    };
    hostId = "80f4ef89";
    hostName = "fourier";
  };

  nix = {
    gc = {
      automatic = true;
      options = "-d";
    };
    settings = {
      max-jobs = 16;
      system-features = [ "benchmark" "nixos-test" "big-parallel" "kvm" ];
    };
  };

  security.pam.loginLimits = [
    { domain = "*"; type = "-"; item = "memlock"; value = "unlimited"; }
    { domain = "*"; type = "-"; item = "nofile"; value = "1048576"; }
    { domain = "*"; type = "-"; item = "nproc"; value = "unlimited"; }
  ];

  services = {
    chrony = {
      enable = true;
      servers = [ "time.nist.gov" "time.cloudflare.com" "time.google.com" "tick.usnogps.navy.mil" ];
      extraConfig = ''
        allow 10.0.0.0/24
      '';
    };
    fstrim.enable = true;
    fwupd.enable = true;
    grafana = {
      enable = true;
      addr = "0.0.0.0";
      extraOptions.DASHBOARDS_MIN_REFRESH_INTERVAL = "1s";
    };
    plex = {
      enable = true;
      openFirewall = true;
    };
    smartd.enable = true;
    syncthing = {
      enable = true;
      group = "media";
      guiAddress = "0.0.0.0:8384";
      openDefaultPorts = true;
      devices = {
        bohr.id = "IBTRLZT-R5UVCQ5-3OT3RT3-V74EA5I-A7W6EA5-BEMUZYQ-GSRGG2B-B7OTGAA";
        hegel.id = "MX6M6ZF-Z7S74CI-EH3EKCY-SC4RYJ2-DXFT47D-EWKAQ5U-5G4KKWH-JRVPGAA";
      };
      folders.music = {
        devices = [ "bohr" "hegel" ];
        path = "/srv/music";
        type = "sendonly";
      };
    };
    zfs.autoScrub.pools = [ "tank" ];
    zfs.autoSnapshot = {
      enable = true;
      flags = "-k -p --utc";
    };
  };

  system.activationScripts.setIOScheduler = ''
    disks=(sda sdb sdc sdd nvme0n1)
    for disk in "''${disks[@]}"; do
      echo "none" > /sys/block/$disk/queue/scheduler
    done
  '';

  systemd.network.networks.eth = {
    matchConfig.MACAddress = "18:c0:4d:31:0c:5f";
    DHCP = "yes";
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/6075a47d-006a-4dbb-9f86-671955132e2f"; }];

  time.timeZone = "America/New_York";

  users.groups.media.members = [ "bemeurer" "plex" ];

  virtualisation = {
    oci-containers.backend = "podman";
    podman.enable = true;
  };

  age.secrets.rootPassword.file = ./password.age;
  users.users.root.passwordFile = config.age.secrets.rootPassword.path;
}

{ config, ... }: {
  age.secrets.nixosAarch64BuilderKey.file = ./key.age;

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "aarch64.nixos.community";
        maxJobs = 64;
        sshKey = config.age.secrets.nixosAarch64BuilderKey.path;
        sshUser = "lovesegfault";
        systems = [ "aarch64-linux" ];
        supportedFeatures = [ "big-parallel" ];
      }
    ];
  };

  programs.ssh = {
    extraConfig = ''
      Host aarch64.nixos.community 147.75.77.190
        IPQoS throughput
    '';

    knownHosts.aarch64-build-box = {
      extraHostNames = [ "aarch64.nixos.community" "147.75.77.190" ];
      publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
    };
  };
}

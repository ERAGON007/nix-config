{
  imports = [ ./documentation.nix ];

  environment = {
    enableDebugInfo = true;
  };

  services.udev.extraRules = ''
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="dialout", TAG+="uaccess"
  '';
}

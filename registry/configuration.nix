{
  modulesPath,
  lib,
  pkgs,
  config,
  ...
}@args:
{
  imports = [
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  system.stateVersion = "26.05";

  networking.hostName = "registry";

  #networking.networkmanager.dhcp = "dhcpcd";

  sops.age.keyFile = "/etc/nixos/age.agekey";

  networking = {
    interfaces = {
      ens18.ipv4.addresses = [
        {
          address = "192.168.1.216";
          prefixLength = 24;
        }
      ];

    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # blau2 has no password, so sudo must not ask for one.
  security.sudo.wheelNeedsPassword = false;

  users.users.blau2 = {
    isNormalUser = true;
    home = "/home/blau2";
    description = "blau2 admin";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnx/ZGyG6ED/Pe1SUWEDeGhuAl5PV6thdet6Pu9p55z blau@blau-pc"
    ];
  };
}

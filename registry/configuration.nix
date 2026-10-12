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
  # Registry is only reachable through Caddy (see below).
  services.dockerRegistry = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 5000;
    openFirewall = false;
    storagePath = "/var/lib/docker-registry";
  };

  # DuckDNS API token (used by Caddy for the ACME DNS challenge).
  sops.secrets.duckdns_token.sopsFile = ../secrets/secrets.yaml;
  sops.templates."caddy-env".content = ''
    DUCKDNS_API_TOKEN=${config.sops.placeholder.duckdns_token}
  '';

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/duckdns@v0.5.1-0.20250419031416-86ea11d23d37" ];
      hash = "sha256-LAFucXh+1L5ekIg9sxFiPFeM1Ye7ZxI7rCDNzdrZIg4=";
    };
    environmentFile = config.sops.templates."caddy-env".path;
    # A named site gets automatic HTTPS; port 80 redirects to HTTPS.
    virtualHosts."bhcr8192.duckdns.org".extraConfig = ''
      tls {
        dns duckdns {env.DUCKDNS_API_TOKEN}
      }
      reverse_proxy 127.0.0.1:5000
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  security.sudo.wheelNeedsPassword = false;

  users.users.blau = {
    isNormalUser = true;
    home = "/home/blau";
    description = "blau admin";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnx/ZGyG6ED/Pe1SUWEDeGhuAl5PV6thdet6Pu9p55z blau@blau-pc"
    ];
  };
}

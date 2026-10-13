{ config, pkgs, ... }:
{
  networking.hostName = "dev";

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "prohibit-password";
  };

  services.qemuGuest.enable = true;
  services.cloud-init.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Login prompt on serial console (so `virtctl console dev` works)
  systemd.services."serial-getty@ttyS0".enable = true;

  users.users.blau = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnx/ZGyG6ED/Pe1SUWEDeGhuAl5PV6thdet6Pu9p55z blau@blau-pc"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git vim tmux ripgrep fd htop
  ];

  system.stateVersion = "26.05";
}

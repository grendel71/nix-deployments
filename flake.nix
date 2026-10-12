{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=25.11";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  inputs.comin.url = "github:nlewo/comin";
  inputs.comin.inputs.nixpkgs.follows = "nixpkgs";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  outputs =
    {
      nixpkgs,
      disko,
      comin,
      sops-nix,
      ...
    }:
    {
      nixosConfigurations.registry = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./registry/configuration.nix
          ./registry/hardware-configuration.nix
          ./common/generic.nix
          ./common/pkgs.nix
          comin.nixosModules.comin
          (
            { ... }:
            {
              services.comin = {
                enable = true;
                hostname = "registry";
                remotes = [
                  {
                    name = "origin";
                    url = "https://github.com/grendel71/devclusterintra.git";
                    branches.main.name = "main";
                  }
                ];
              };
            }
          )
        ];
      };
    };
}

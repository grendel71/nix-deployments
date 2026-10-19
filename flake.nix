{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=26.05";
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
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./image/configuration.nix ./image/qcow.nix ];
      };
      qcow = nixos.config.system.build.qcow2;

      containerDisk = pkgs.dockerTools.buildLayeredImage {
        name = "nixos-dev";
        tag = "latest";
        # The qcow2 embeds store paths. Without this, the whole NixOS
        # closure is copied into the image as extra layers.
        includeStorePaths = false;
        enableFakechroot = true;
        fakeRootCommands = ''
          mkdir -p /disk
          cp ${qcow}/nixos.qcow2 /disk/nixos.qcow2
          chown -R 107:107 /disk
          chmod 0644 /disk/nixos.qcow2
        '';
      };

      # skopeo needs a trust policy. Many systems have no policy.json.
      policy = pkgs.writeText "policy.json" (builtins.toJSON {
        default = [ { type = "insecureAcceptAnything"; } ];
      });

      # Usage: nix run .#push -- <registry>/<name>:<tag> [skopeo flags]
      # Example: nix run .#push -- localhost:5000/nixos-dev:latest --dest-tls-verify=false
      push = pkgs.writeShellApplication {
        name = "push-container-disk";
        runtimeInputs = [ pkgs.skopeo ];
        text = ''
          if [ "$#" -lt 1 ]; then
            echo "usage: push <registry>/<name>:<tag> [skopeo flags]" >&2
            exit 1
          fi
          dest="$1"
          shift
          skopeo --policy ${policy} copy "$@" "docker-archive:${containerDisk}" "docker://$dest"
        '';
      };
 
    in {
      packages.${system} = {
        qcow2 = qcow;
        containerDisk = containerDisk;
        default = qcow;
      };

      apps.${system}.push = {
        type = "app";
        program = "${push}/bin/push-container-disk";
      };
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
                    url = "https://github.com/grendel71/nix-deployments.git";
                    branches.main.name = "main";
                  }
                ];
              };
            }
          )
        ];
      };
      nixosConfigurations.proxy = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./proxy/configuration.nix
          ./proxy/hardware-configuration.nix
          ./common/generic.nix
          ./common/pkgs.nix
          comin.nixosModules.comin
          (
            { ... }:
            {
              services.comin = {
                enable = true;
                hostname = "proxy";
                remotes = [
                  {
                    name = "origin";
                    url = "https://github.com/grendel71/nix-deployments.git";
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

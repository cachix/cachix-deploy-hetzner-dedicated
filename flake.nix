{
  description = "";

  inputs = {
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
  };

  outputs = { nixpkgs, cachix-deploy-flake, ... }: 
    let
      # change these 
      machineName = "myagent";
      sshPubKey = "ssh-rsa XXX me@machine";

      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      common = system: rec {
        pkgs = nixpkgs.legacyPackages.${system};
        cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
        bootstrapNixOS = cachix-deploy-lib.bootstrapNixOS { 
          system = system; 
          hostname = machineName;
          grubDevices = [ "/dev/nvme0n1"  "/dev/nvme1n1" ];
          sshPubKey = sshPubKey;
        };
      };
    in {
      nixosConfigurations.${machineName} = (common "x86_64-linux").bootstrapNixOS.nixos;

      packages = forAllSystems (system: 
        let 
          inherit (common system) pkgs cachix-deploy-lib bootstrapNixOS;
        in {
        default = cachix-deploy-lib.spec {
            agents = {
              "${machineName}" = cachix-deploy-lib.nixos {
                imports = [ bootstrapNixOS.module ];

                config = {
                  # here comes all your NixOS configuration
                };
              };
            };
          };
        });
          
      devShells = forAllSystems (system: 
        let 
          inherit (common system) pkgs;
        in { 
        default = pkgs.mkShell {
          buildInputs = [
            cachix-deploy-flake.packages.${system}.bootstrapHetzner
          ];
        };
      });
  }; 
}
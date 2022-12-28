{
  description = "";

  inputs = {
    nixos-remote.url = "github:numtide/nixos-remote";
    nixos-remote.inputs.nixpkgs.follows = "nixpkgs";
    nixos-remote.inputs.disko.follows = "disko";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
  };

  outputs = { nixpkgs, nixos-remote, disko, cachix-deploy-flake, ... }: 
    let
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      # TODO: move to cachix-deploy-flake-lib
      bootstrapNixOS = { system, hostname, disks, sshPubKey }: lib.nixosSystem {
        system = system;
        modules = [
          disko.nixosModules.disko
          ({ pkgs, ... }: {
            services.cachix-agent.enable = true;
            networking.hostName = hostname;
            disko.devices = import "${disko}/example/mdadm.nix" { inherit disks; };
            boot.loader.grub.devices = disks;
            # enable nvme https://github.com/nix-community/disko/issues/96
            boot.initrd.availableKernelModules = [ "nvme" ];
            
            # add root ssh key
            users.users.root.openssh.authorizedKeys.keys = [ sshPubKey ];
            # enable ssh
            services.openssh.enable = true;
            # enable passwordless ssh for root 
            services.openssh.permitRootLogin = "without-password";
          })
        ];
      };
    in {
      nixosConfigurations.myagent = bootstrapNixOS { 
        system = "x86_64-linux"; 
        hostname = "myagent";
        disks = [ "/dev/nvme0n1"  "/dev/nvme1n1" ];
        sshPubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7CTy+OMdA1IfR3EEuL/8c9tWZvfzzDH9cYE1Fq8eFsSfcoFKtb/0tAcUrhYmQMJDV54J7cLvltaoA4MV788uKl+rlqy17rKGji4gC94dvtB9eIH11p/WadgGORnjdiIV1Df29Zmjlm5zqNo2sZUxs0Nya2I4Dpa2tdXkw6piVgMtVrqPCM4W5uorX8CE+ecOUzPOi11lyfCwLcdg0OugXBVrNNSfnJ2/4PrLm7rcG4edbonjWa/FvMAHxN7BBU5+aGFC5okKOi5LqKskRkesxKNcIbsXHJ9TOsiqJKPwP0H2um/7evXiMVjn3/951Yz9Sc8jKoxAbeH/PcCmMOQz+8z7cJXm2LI/WIkiDUyAUdTFJj8CrdWOpZNqQ9WGiYQ6FHVOVfrHaIdyS4EOUG+XXY/dag0EBueO51i8KErrL17zagkeCqtI84yNvZ+L2hCSVM7uDi805Wi9DTr0pdWzh9jKNAcF7DqN16inklWUjtdRZn04gJ8N5hx55g2PAvMYWD21QoIruWUT1I7O9xbarQEfd2cC3yP+63AHlimo9Aqmj/9Qx3sRB7ycieQvNZEedLE9xiPOQycJzzZREVSEN1EK1xzle0Hg6I7U9L5LDD8yXkutvvppFb27dzlr5MTUnIy+reEHavyF9RSNXHTo57myffl8zo2lPjcmFkffLZQ== ielectric@kaki
";
      };

      packages = forAllSystems (system: let 
        pkgs = nixpkgs.legacyPackages.${system};
        cachix-deploy-lib = cachix-deploy-flake.lib pkgs;
        in cachix-deploy-lib.spec {
            agents = {
              myagent = cachix-deploy-lib.nixos {

                imports = []; # TODO: from bootstrap

                config = {

                };
              };
            };
          }
      );
      
      devShells = forAllSystems (system: let 
        pkgs = nixpkgs.legacyPackages.${system};
        bootstrapHetzner = pkgs.writeScriptBin "bootstrap-hetzner" ''
          #!${pkgs.runtimeShell}

          # error out if not two arguments are given
          if [ "$#" -ne 3 ]; then
            echo "Usage: $0 <IP> <agent-hostname> <cachix-agent-token-path>"
            echo "Example: $0 1.1.1.1 myagent ./mytoken.secret"
            exit 1
          fi

          echo "Bootstrapping $2 on $1 ..."
          echo "Make sure your ssh key is added to the ssh-agent to prevent multiple password prompts."

          IP="$1"
          agent="$2"
          agenttokenpath="$3"

          ${nixos-remote.packages.${system}.default}/bin/nixos-remote "root@$IP" --flake ".#$agent"

          scp $agenttokenpath root@$IP:/etc/cachix-agent.token
          ssh root@$IP systemctl restart cachix-agent

          echo "Done."
        '';
      in { default = pkgs.mkShell {
        buildInputs = [
          bootstrapHetzner
        ];
    };});
    }; 
}
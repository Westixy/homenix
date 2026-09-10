{
  description = "NixOS configuration for westixy's machines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Zen Browser is no longer packaged in nixpkgs; use the community flake.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, zen-browser, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      initScript = pkgs.writeShellScriptBin "init-from-fresh-install" ''
        export PATH="${pkgs.lib.makeBinPath (with pkgs; [ git coreutils ])}:''${PATH:-/usr/bin:/bin}"
        ${builtins.readFile ./init-from-fresh-install.sh}
      '';
    in
    {
      nixosConfigurations.auberge = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./systems/auberge/configuration.nix ];
      };
      nixosConfigurations.auberge-gpd = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ ./systems/auberge-gpd/configuration.nix ];
      };

      packages.${system} = {
        inherit initScript;
        init-from-fresh-install = initScript;
      };

      apps.${system}.i = {
        type = "app";
        program = "${initScript}/bin/init-from-fresh-install";
        meta.description = "alias for init-from-fresh-install";
      };
    };
}

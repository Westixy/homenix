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
    {
      nixosConfigurations.auberge = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ ./systems/auberge/configuration.nix ];
      };
      nixosConfigurations.auberge-gpd = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [ ./systems/auberge-gpd/configuration.nix ];
      };
    };
}

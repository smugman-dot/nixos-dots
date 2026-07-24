{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    thorium-browser.url = "path:/home/walid/thorium-nix";

    proton-cachyos.url = "github:powerofthe69/proton-cachyos-nix";

    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    gsr-ui-nix = {
      url = "github:rPlakama/gsr-ui-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      nix-cachyos-kernel,
      noctalia,
      spicetify-nix,
      thorium-browser,
      millennium,
      proton-cachyos,
      lanzaboote,
      mangowm,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.smoke = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = { inherit inputs; };
        modules = [
          inputs.gsr-ui-nix.nixosModules.default
          inputs.mangowm.nixosModules.mango

          ({ ... }: {
            nixpkgs.overlays = [
              nix-cachyos-kernel.overlays.pinned
              proton-cachyos.overlays.default
              inputs.millennium.overlays.default
              (final: prev: {
                faugus-launcher = pkgs-unstable.faugus-launcher;
              })
            ];
          })

          ./configuration.nix

          home-manager.nixosModules.home-manager

          lanzaboote.nixosModules.lanzaboote

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };

              users.walid = import ./home.nix;

              backupFileExtension = "backup";
            };
          }

        ];
      };
    };
}

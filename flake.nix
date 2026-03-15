{
  description = "My NixOS config";

  inputs = {
    nixpkgs.url = "tarball+https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    nixpkgs-unstable.url = "tarball+https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz";
    home-manager = {
      url = "tarball+https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code = {
      url = "tarball+https://github.com/sadjow/claude-code-nix/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "tarball+https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    serena = {
      url = "tarball+https://github.com/oraios/serena/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "tarball+https://github.com/nix-community/lanzaboote/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, claude-code, rust-overlay, serena, lanzaboote }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    personal = import ./config/personal.nix;
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit claude-code serena personal rust-overlay lanzaboote; };
      modules = [
        ./hosts/nixos
        lanzaboote.nixosModules.lanzaboote
        home-manager.nixosModules.home-manager
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            (import rust-overlay)
            (final: prev:
            let
              unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            in {
              firefox = unstable.firefox;
              # linuxPackages_latest = unstable.linuxPackages_latest.extend (kfinal: kprev: {
              #   opensnitch-ebpf = kprev.opensnitch-ebpf.overrideAttrs (old: {
              #     preBuild = (old.preBuild or "") + ''
              #       makeFlagsArray+=("EXTRA_FLAGS=-Wno-microsoft-anon-tag -fms-extensions")
              #     '';
              #   });
              # });
            })
            (final: prev: {
              lazyworktree = prev.buildGoModule rec {
                pname = "lazyworktree";
                version = "1.25.1";
                src = prev.fetchFromGitHub {
                  owner = "chmouel";
                  repo = "lazyworktree";
                  rev = "v${version}";
                  hash = "sha256-uMpTlv+Et3nlYN7obEOjWypCNMNcZ4FpTG8Yxl26HPE=";
                };
                vendorHash = "sha256-UdAkEtU531MaCr13HOIi79TWoKEzLbbfwc04ftv5ubc=";
                doCheck = false;
              };

            })
          ];
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit claude-code serena personal; };
          home-manager.users.dima = import ./users/dima;
        }
      ];
    };
  };
}

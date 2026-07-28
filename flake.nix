{
  description = "Sun After Rome - LÖVE RTS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        luajit = pkgs.luajit;
        enet = pkgs.enet;
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "sun-after-rome";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ pkgs.zip ];
          buildPhase = ''
            zip -r sun-after-rome.love . -x '*.git*' '*.nix' 'flake.lock' 'result'
          '';
          installPhase = ''
            mkdir -p $out/share
            cp sun-after-rome.love $out/share/
          '';
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.lua5_4
            pkgs.git
          ];

          buildInputs = [
            luajit
            enet
          ];

          shellHook = ''
            echo "Sun After Rome dev shell"
            echo "  love .          — run game (love must be installed externally)"
            echo "  make test       — run test suite"
            echo "  make smoke-test — run LÖVE smoke test (catches runtime errors)"
            echo "  nix build       — package as .love file"
            echo ""
            echo "LÖVE is not in nixpkgs yet. Install manually:"
            echo "  macOS: brew install love"
            echo "  Linux: https://love2d.org/wiki/Installing_LÖVE"
            echo ""
            echo "ENet paths for make enet:"
            export LUAJIT_INC="${luajit}/include/luajit-2.1"
            export ENET_INC="${enet}/include"
            export ENET_LIB="${enet}/lib"
            export LUAJIT_LIB="luajit-5.1"
          '';
        };
      });
}

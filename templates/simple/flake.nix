{
  description = "My Idris 2 package";

  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.idris2-pkgs.url = github:claymager/idris2-pkgs;

  outputs = { self, nixpkgs, idris2-pkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };

        # Idris2, and the libraries you want available
        idris2 = pkgs.idris2.withPackages
          (ps: with ps; [
            comonad
            elab-util
            sop
          ])
          in
          rec {

          devShell = pkgs.mkShell {
          buildInputs = [ idris2 pkgs.rlwrap ];
        shellHook = ''
          alias idris2="rlwrap -s 1000 idris2 --no-banner"
        '';
        };

        }
        );
        }

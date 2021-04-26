{
  description = "A very basic flake";

  inputs.idris2-src = {
    url = github:idris-lang/idris2;
    flake = false;
  };

  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, idris2-src, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          idris2 = pkgs.callPackage ./idris2 { inherit idris2-src; };
        in
        {
          defaultPackage = idris2;

          devShell = pkgs.mkShell {
            buildInputs = [
              pkgs.nixpkgs-fmt
            ];
          };

        }
      ) // {

      overlay = final: prev: {
        idris2 = prev.callPackage ./idris2 { inherit idris2-src; };
      };

      templates = import ./templates;
    };
}

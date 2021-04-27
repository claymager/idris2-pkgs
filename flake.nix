{
  description = "Idris2 and its packages";

  inputs.idris2-src = {
    url = github:idris-lang/idris2;
    flake = false;
  };

  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, idris2-src, flake-utils }:
    {
      overlay = final: prev: {
        idris2 = prev.callPackage ./idris2 { inherit idris2-src; };
      };

      templates = import ./templates;
    } //

    # Without the racket backend, we can't build on ARM yet.
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
        in
        {
          packages.idris2 = pkgs.idris2;

          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };

        }
      );

}

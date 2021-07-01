{
  description = "My Idris 2 package";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.idris2-pkgs.url = "github:claymager/idris2-pkgs";

  outputs = { self, nixpkgs, idris2-pkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" "i686-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };

        # Idris2, and any libraries you want available
        idris2-with-pkgs = pkgs.idris2.withPackages
          (ps: with ps; [
            idris2api
          ]);
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = [ idris2-with-pkgs ];
        };
      }
    );
}

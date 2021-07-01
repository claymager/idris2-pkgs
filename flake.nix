{
  description = "Idris2 and its packages";

  inputs.idris2-src = {
    url = "github:idris-lang/idris2";
    flake = false;
  };

  inputs.flake-utils.url = "github:numtide/flake-utils";

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
          idrisPackages = pkgs.idris2.packages;
        in
        {
          packages = idrisPackages // { inherit (pkgs) idris2; };

          defaultPackage = pkgs.idris2;

          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };

          checks =
            let
              names = builtins.attrNames idrisPackages;
              mkCheck = nm: {
                name = nm;
                value = idrisPackages.${nm}.asLib;
              };
            in
            # All packages as libraries, and certain executable environments
            builtins.listToAttrs (builtins.map mkCheck names) // {
              lspWithPackages = idrisPackages.lsp.withPackages (ps: [ ps.comonad ]);
            };

        }
      );

}

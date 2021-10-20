{
  description = "Idris2 and its packages";

  inputs = {
    idris2-src = { url = "github:idris-lang/idris2/0a29d06f"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";
    ipkg-to-json = { url = "github:claymager/ipkg-to-json"; flake = false; };

    elab-util = { url = "github:stefan-hoeck/idris2-elab-util"; flake = false; };
    pretty-show = { url = "github:stefan-hoeck/idris2-pretty-show"; flake = false; };
    sop = { url = "github:stefan-hoeck/idris2-sop"; flake = false; };
    dom = { url = "github:stefan-hoeck/idris2-dom"; flake = false; };
    comonad = { url = "github:stefan-hoeck/idris2-comonad"; flake = false; };
    hedgehog = { url = "github:stefan-hoeck/idris2-hedgehog"; flake = false; };
    lsp = { url = "github:idris-community/idris2-lsp"; flake = false; };
    idrall = { url = "github:alexhumphreys/idrall"; flake = false; };
  };

  outputs = { self, nixpkgs, idris2-src, flake-utils, ... }@srcs:
    {
      overlay = final: prev: {
        # just compiler; no builders or packages yet
        idris2 = final.callPackage ./compiler.nix {
          inherit idris2-src;
        };
        lib = prev.lib.recursiveUpdate prev.lib (import ./lib);
      };

      templates = import ./templates;
    } //

    # Without the racket backend, we can't build on ARM yet.
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          sources = builtins.removeAttrs srcs [ "self" "nixpkgs" "flake-utils" "idris2-src" ] // { idris2api = idris2-src; };
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
          idrisPackages = import ./packageSet.nix { idrisCompiler = pkgs.idris2; inherit sources; inherit (pkgs) callPackage lib; };
        in
        {
          packages = idrisPackages // { inherit (pkgs) idris2; };

          defaultPackage = pkgs.idris2;

          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };

          /* `$ nix flake check` (and `.. show`) require configured build machines for all systems
            supported by `idris2-pkgs`. This is due to ipkgToNix, which requ

            `$ nix-build -A checks.CURRENT_SYSTEM` behaves as expected, and is used in the CI.
          */
          checks =
            let
              names = pkgs.lib.lists.subtractLists [ "_builders" ] (builtins.attrNames idrisPackages);
              mkCheck = nm: {
                name = nm;
                value = idrisPackages.${nm}.asLib;
              };
            in
            # All packages as libraries, and certain executable environments
            builtins.trace (builtins.toString names)
              builtins.listToAttrs
              (builtins.map mkCheck names) // {
              lspWithPackages = idrisPackages.lsp.withPackages (ps: [ ps.comonad ]);
            };

        }
      );

}

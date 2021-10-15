{
  description = "Idris2 and its packages";

  inputs.idris2-src = {
    url = "github:idris-lang/idris2";
    flake = false;
  };

  inputs.elab-util = { url = "github:stefan-hoeck/idris2-elab-util"; flake = false; };
  inputs.pretty-show = { url = "github:stefan-hoeck/idris2-pretty-show"; flake = false; };
  inputs.sop = { url = "github:stefan-hoeck/idris2-sop"; flake = false; };

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, idris2-src, flake-utils, ... }@srcs:
    let
      packageSrcs = builtins.removeAttrs srcs [ "self" "nixpkgs" "idris2-src" "flake-utils" ];
      packageSet = buildIdris:
        let
          buildIdrisRepo = import utils/buildRepo.nix { inherit buildIdris; lib = nixpkgs.lib; };
        in
        rec {
          elab-util = buildIdrisRepo srcs.elab-util { };
          sop = buildIdrisRepo srcs.sop { idrisLibraries = [ elab-util ]; };
          pretty-show = buildIdrisRepo srcs.pretty-show { idrisLibraries = [ sop elab-util ]; };
        };
    in
    {
      overlay = final: prev: {
        idris2 = prev.callPackage ./idris2 {
          inherit idris2-src;
        };
      };

      templates = import ./templates;
    } //

    # Without the racket backend, we can't build on ARM yet.
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
          idrisPackages = packageSet (pkgs.idris2.buildIdris);
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
              # lspWithPackages = idrisPackages.lsp.withPackages (ps: [ ps.comonad ]);
            };

        }
      );

}

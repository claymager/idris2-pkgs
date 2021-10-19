{
  description = "Idris2 and its packages";

  inputs = {
    idris2-src = { url = "github:idris-lang/idris2/0a29d06f"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";
    ipkg-to-json = { url = "github:claymager/ipkg-to-json"; flake = false; };

    elab-util = { url = "github:stefan-hoeck/idris2-elab-util"; flake = false; };
    pretty-show = { url = "github:stefan-hoeck/idris2-pretty-show"; flake = false; };
    sop = { url = "github:stefan-hoeck/idris2-sop"; flake = false; };
    hedgehog = { url = "github:stefan-hoeck/idris2-hedgehog"; flake = false; };
    lsp = { url = "github:idris-community/idris2-lsp"; flake = false; };
    idrall = { url = "github:alexhumphreys/idrall"; flake = false; };
  };

  outputs = { self, nixpkgs, idris2-src, flake-utils, ... }@srcs:
    let
      packageSet = { buildIdris, callPackage, stdenv }:
        let
          # utils
          ipkgToNix = callPackage ./utils/ipkg-to-json { inherit buildIdris; src = srcs.ipkg-to-json; };
          buildIdrisRepo = callPackage utils/buildRepo.nix { inherit buildIdris ipkgToNix; };
        in
        rec {
          idris2api = buildIdrisRepo idris2-src {
            ipkgFile = "idris2api.ipkg";
            name = "idris2api";
            preBuild = ''
              LONG_VERSION=$(idris2 --version)
              ARR=($(echo $LONG_VERSION | sed 's/-/ /g; s/\./,/g' ))
              VERSION="((''${ARR[-2]}), \"${idris2-src.shortRev}\")"

              echo 'module IdrisPaths' >> src/IdrisPaths.idr
              echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $VERSION" >> src/IdrisPaths.idr
              echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
            '';
          };
          elab-util = buildIdrisRepo srcs.elab-util { };
          lsp = buildIdrisRepo srcs.lsp { idrisLibraries = [ idris2api ]; runtimeLibs = true; };
          idrall = buildIdrisRepo srcs.idrall { };
          sop = buildIdrisRepo srcs.sop { idrisLibraries = [ elab-util ]; };
          pretty-show = buildIdrisRepo srcs.pretty-show { idrisLibraries = [ sop elab-util ]; };
          hedgehog = buildIdrisRepo srcs.hedgehog { idrisLibraries = [ sop elab-util pretty-show ]; };
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
          idrisPackages = packageSet { buildIdris = (pkgs.idris2.buildIdris); inherit (pkgs) callPackage stdenv; };
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

{
  description = "Idris2 and its packages";

  inputs.idris2-src = {
    url = "github:idris-lang/idris2/0a29d06f";
    flake = false;
  };

  inputs.elab-util = { url = "github:stefan-hoeck/idris2-elab-util"; flake = false; };
  inputs.pretty-show = { url = "github:stefan-hoeck/idris2-pretty-show"; flake = false; };
  inputs.sop = { url = "github:stefan-hoeck/idris2-sop"; flake = false; };
  inputs.hedgehog = { url = "github:stefan-hoeck/idris2-hedgehog"; flake = false; };
  inputs.lsp = { url = "github:idris-community/idris2-lsp"; flake = false; };
  inputs.idrall = { url = "github:alexhumphreys/idrall"; flake = false; };

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, idris2-src, flake-utils, ... }@srcs:
    let
      packageSrcs = builtins.removeAttrs srcs [ "self" "nixpkgs" "idris2-src" "flake-utils" ];
      packageSet = buildIdris:
        let
          buildIdrisRepo = import utils/buildRepo.nix { inherit buildIdris; lib = nixpkgs.lib; };
          # buildIdrisRepo = pkgs.dhallToNix "${./utils/buildRepo.dhall}" { inherit buildIdris; lib = nixpkgs.lib; };
        in
        rec {
          elab-util = buildIdrisRepo srcs.elab-util { };
          lsp = buildIdrisRepo srcs.lsp {
            idrisLibraries = [ idris2api ];
            runtimeLibs = true;
            executable = "idris2-lsp";
          };
          idrall = buildIdrisRepo srcs.idrall { };
          idris2api = buildIdrisRepo srcs.idris2-src {
            ipkgFile = "idris2api.ipkg";
            name = "idris2api";
            preBuild = ''
              # get correct version information
              IFS=' -' read -ra ARR <<< $(idris2 --version)
              VERSION=$(sed 's/\./,/g' <<< ''${ARR[-2]})
              IDRIS_VERSION="(($VERSION), \"${srcs.idris2-src.shortRev}\")"

              # make IdrisPaths
              echo 'module IdrisPaths' >> src/IdrisPaths.idr
              echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $IDRIS_VERSION" >> src/IdrisPaths.idr
              echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
            '';
          };
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

{ buildIdris, callPackage, lib, srcs }:
let
  inherit (builtins) elem filter attrNames removeAttrs;
  inherit (lib) subtractLists recursiveUpdate;

  # utils
  ipkgToNix = callPackage ./utils/ipkg-to-json { inherit buildIdris; src = srcs.ipkg-to-json; };

  choosePkgs = ps: extraPkgs: depends:
    let
      ipkgs = recursiveUpdate ps extraPkgs;
      savedPkgNames = attrNames extraPkgs;
      notDefault = p: !(elem p (subtractLists savedPkgNames [ "network" "test" "contrib" "base" "prelude" ]));
      pkgNames = removeAttrs
        {
          "idris2" = "idris2api";
        }
        savedPkgNames;
      renameDeps = dep: pkgNames."${dep}" or dep;
      depNames = map renameDeps (filter notDefault (map (d: d.name) depends));
    in
    map (d: ipkgs."${d}") depNames;

  buildIdrisRepo = callPackage utils/buildRepo.nix
    {
      inherit buildIdris ipkgToNix;
      pkgmap = choosePkgs packageSet;
    };

  packageSet = rec {
    idris2api = buildIdrisRepo srcs.idris2-src {
      ipkgFile = "idris2api.ipkg";
      name = "idris2api";
      preBuild = ''
        LONG_VERSION=$(idris2 --version)
        ARR=($(echo $LONG_VERSION | sed 's/-/ /g; s/\./,/g' ))
        VERSION="((''${ARR[-2]}), \"${srcs.idris2-src.shortRev}\")"

        echo 'module IdrisPaths' >> src/IdrisPaths.idr
        echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $VERSION" >> src/IdrisPaths.idr
        echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
      '';
    };
    dom = buildIdrisRepo srcs.dom { ipkgFile = "dom.ipkg"; };
    ipkg-to-json = buildIdrisRepo srcs.ipkg-to-json { };
    elab-util = buildIdrisRepo srcs.elab-util { };
    lsp = buildIdrisRepo srcs.lsp { runtimeLibs = true; };
    idrall = buildIdrisRepo srcs.idrall { };
    sop = buildIdrisRepo srcs.sop { };
    pretty-show = buildIdrisRepo srcs.pretty-show { };
    hedgehog = buildIdrisRepo srcs.hedgehog { };
  };
in
packageSet

{ buildIdris, callPackage, lib, srcs }:
let
  inherit (builtins) filter elem;
  # utils
  ipkgToNix = callPackage ./utils/ipkg-to-json { inherit buildIdris; src = srcs.ipkg-to-json; };

  filterSrcs = ps: depends:
    let
      notDefault = p: !elem p [ "network" "test" "contrib" "base" "prelude" ];

      pkgNames = {
        "idris2" = "idris2api";
      };

      renameDeps = dep: pkgNames."${dep}" or dep;

      depNames = map renameDeps (filter notDefault (map (d: d.name) depends));
    in
    map (d: ps."${d}") depNames;

  buildIdrisRepo = callPackage utils/buildRepo.nix
    {
      inherit buildIdris ipkgToNix;
      pkgmap = filterSrcs packageSet;
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

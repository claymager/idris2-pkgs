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
          #  name-in-ipkg = name-in-idris2-pks;
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

  configOverrides = {
    lsp.runtimeLibs = true;
    dom.ipkgFile = "dom.ipkg";
    idris2api = {
      ipkgFile = "idris2api.ipkg";
      name = "idris2api";
      preBuild = ''
        LONG_VERSION=$(idris2 --version)
        ARR=($(echo $LONG_VERSION | sed 's/-/ /g; s/\./,/g' ))
        VERSION="((''${ARR[-2]}), \"${srcs.idris2api.shortRev}\")"

        echo 'module IdrisPaths' >> src/IdrisPaths.idr
        echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $VERSION" >> src/IdrisPaths.idr
        echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
      '';
    };
  };

  extraPackages = rec {
    readline-sample = callPackage ({ readline }:
      buildIdrisRepo srcs.idris2api {
        buildInputs = [ readline ];
        ipkgFile = "samples/FFI-readline/readline.ipkg";
        preBuild = ''
          # idris-lang/Idris2 (#1179)
          sed -i 's/^\(#include <readline\)/#include <stdio.h>\n\1/' samples/FFI-readline/readline_glue/idris_readline.c
        '';
      }) { };
  };

  packageSet = (mapAttrs
    (name: src:
      let cfg = configOverrides."${name}" or { }; in
      buildIdrisRepo (getAttr name srcs) cfg)
    srcs) // extraPackages;
in
packageSet

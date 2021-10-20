{ idrisCompiler, callPackage, lib, sources }:
let
  inherit (builtins) elem filter attrNames removeAttrs getAttr mapAttrs;
  inherit (lib) subtractLists recursiveUpdate maybeAttr;

  renamePkgs = {
    #  name-in-ipkg = name-in-idris2-pks;
    "idris2" = "idris2api";
  };

  builders = callPackage ./utils
    {
      inherit renamePkgs;
      inherit (sources) ipkg-to-json;
      idris2 = idrisCompiler;
    }
    packageSet;

  inherit (builders) idrisPackage;

  /* Configuration for the primary packges of each flake input.

    If you would call
    #   dom = idrisPackage sources.dom { ipkgFile = "dom.ipkg" };
    set that here instead.
  */
  packageConfig = {

    lsp.runtimeLibs = true;

    dom.ipkgFile = "dom.ipkg";

    idris2api = {
      ipkgFile = "idris2api.ipkg";
      name = "idris2api";
      preBuild = ''
        LONG_VERSION=$(idris2 --version)
        ARR=($(echo $LONG_VERSION | sed 's/-/ /g; s/\./,/g' ))
        VERSION="((''${ARR[-2]}), \"${sources.idris2api.shortRev}\")"

        echo 'module IdrisPaths' >> src/IdrisPaths.idr
        echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $VERSION" >> src/IdrisPaths.idr
        echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
      '';
    };

  };

  /* Packages that are *not* named in the flake inputs go here. */
  extraPackages = rec {

    /* Please don't depend on readline-sample; it is included primarily as an example.
      As the ecosystem imprroves, this will probably removed.
    */
    readline-sample = callPackage
      ({ readline }:
        idrisPackage sources.idris2api {
          buildInputs = [ readline ];
          ipkgFile = "samples/FFI-readline/readline.ipkg";
          preBuild = ''
            # idris-lang/Idris2 (#1179)
            sed -i 's/^\(#include <readline\)/#include <stdio.h>\n\1/' samples/FFI-readline/readline_glue/idris_readline.c
          '';
        })
      { };
  };

  packageSet = (mapAttrs
    (name: src:
      let cfg = maybeAttr { } name packageConfig; in
      idrisPackage (getAttr name sources) cfg)
    sources) // extraPackages;

in
packageSet // { _builders = builders; }



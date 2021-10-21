{ lib, sources }: callPackage: idrisCompiler:
let
  /* If idris2-pkgs and the idris2 compiler call the same package different names,
    tell us about that here.
  */
  renamePkgs = {
    #  name-in-ipkg = name-in-idris2-pkgs;
    "idris2" = "idris2api";
  };

  /* Configuration for the primary packges of each flake input.

    If you would call
    *   dom = idrisPackage sources.dom { ipkgFile = "dom.ipkg" };
    set that here instead.
  */
  packageConfig = {

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

  /* Names of packages which require access to idris TTC files at runtime. */
  needRuntimeLibs = [
    "lsp"
  ];

  /* end of configuration section */
  inherit (builtins) elem getAttr mapAttrs;
  inherit (builders) idrisPackage useRuntimeLibs;
  builders = callPackage ./utils
    {
      inherit renamePkgs;
      inherit (sources) ipkg-to-json;
      idris2 = idrisCompiler;
    }
    allPackages;

  allPackages =
    let
      primaryPackages = mapAttrs
        (name: src:
          let cfg = lib.maybeAttr { } name packageConfig; in
          idrisPackage (getAttr name sources) cfg)
        sources;
    in
    primaryPackages // extraPackages;
in
mapAttrs (name: pkg: if (elem name needRuntimeLibs) then (useRuntimeLibs pkg) else pkg) allPackages // { _builders = builders; }

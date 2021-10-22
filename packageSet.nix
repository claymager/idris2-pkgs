{ lib, sources }: pkgs: idrisCompiler:
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

  /* Packages that are *not* directly named in the flake inputs go here. */
  extraPackages = rec {
    prelude = idrisPackage (sources.idris2api + "/libs/prelude") { idrisLibraries = [ ]; };
    base = idrisPackage (sources.idris2api + "/libs/base") { idrisLibraries = [ ]; };
    contrib = idrisPackage (sources.idris2api + "/libs/contrib") { };
    network = idrisPackage (sources.idris2api + "/libs/network") { };
    test = idrisPackage (sources.idris2api + "/libs/test") { };

    /* The following derivations are provided as examples, but are not to be provided in the build
      outputs of the derivation or repository.

      _idris2 = idrisPackage sources.idris2api {
      ipkgFile = "idris2.ipkg";
      idrisLibraries = [ network allPackages.idris2api ];
      name = "idris3";
      preBuild = ''
      mkdir -p newSrc/Idris
      mv src/Idris/Main.idr newSrc/Idris/Main.idr
      sed -i 's/src/newSrc/; s/network/network, idris2/' idris2.ipkg
      '';
      postBinInstall = ''
      wrapProgram $out/bin/idris2 --set-default CHEZ "${pkgs.chez}/bin/scheme"
      '';
      };

      readline-sample =
      idrisPackage sources.idris2api {
      buildInputs = [ pkgs.readline ];
      ipkgFile = "samples/FFI-readline/readline.ipkg";
      preBuild = ''
      # idris-lang/Idris2 (#1179)
      sed -i 's/^\(#include <readline\)/#include <stdio.h>\n\1/' samples/FFI-readline/readline_glue/idris_readline.c
      '';
      };
    */

  };

  /* Names of packages which require access to idris TTC files at runtime. */
  needRuntimeLibs = [
    # "_idris2"
    "lsp"
  ];

  /* end of configuration section */
  inherit (builtins) elem getAttr mapAttrs;
  inherit (builders) idrisPackage useRuntimeLibs;

  builders = pkgs.callPackage ./utils
    {
      inherit renamePkgs idrisCompiler;
      inherit (sources) ipkg-to-json;
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

{ lib, sources, pkgs, idris2 }:
let
  /* Configuration for the primary packges of each flake input.

    If you would call
    *   dom = idrisPackage sources.dom { ipkgFile = "dom.ipkg" };
    set that here instead.
  */
  packageConfig = {

    dom.ipkgFile = "dom.ipkg";

    idris2 = {
      ipkgFile = "idris2api.ipkg";
      name = "idris2";
      preBuild = ''
        LONG_VERSION=$(idris2 --version)
        ARR=($(echo $LONG_VERSION | sed 's/-/ /g; s/\./,/g' ))
        VERSION="((''${ARR[-2]}), \"${sources.idris2.shortRev or "dirty"}\")"

        echo 'module IdrisPaths' >> src/IdrisPaths.idr
        echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $VERSION" >> src/IdrisPaths.idr
        echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
      '';
    };

    frex = { checkPhase = "make test"; doCheck = true; };

    inigo = {
      buildPhase = ''
        sed 's/: idrall/:/' -i Makefile
        make bootstrap
      '';
      propagatedBuildInputs = [ pkgs.nodejs ];
      postBinInstall = ''
        # Inigo needs idris2 compiler at runtime
        wrapProgram $out/bin/inigo \
          --suffix PATH ':' ${idris2}/bin
      '';
    };

    lsp.patchPhase = ''
      make src/Server/Generated.idr VERSION_TAG=${sources.lsp.shortRev or "dirty"}
    '';

    python.ipkgFile = "python-bindings.ipkg";

    recombine.ipkgFile = "recombine.ipkg";

  };

  /* Packages that are *not* directly named in the flake inputs go here. */
  extraPackages = rec {
    /* idrisPackage usually automatically adds `base` and `prelude` to the environment, so we
      explicitly tell it which packages are required to prevent an infinite loop. */
    prelude = idrisPackage (sources.idris2 + "/libs/prelude") { idrisLibraries = [ ]; };
    base = idrisPackage (sources.idris2 + "/libs/base") { idrisLibraries = [ ]; };

    contrib = idrisPackage (sources.idris2 + "/libs/contrib") { };
    network = idrisPackage (sources.idris2 + "/libs/network") { };
    test = idrisPackage (sources.idris2 + "/libs/test") { };

    idris2-python = idrisPackage (sources.python) {
      ipkgFile = "idris2-python.ipkg";
      postBinInstall = ''
        mkdir -p $out/lib
        mv Idris2Python $out/lib
        # Python relies on the RefC backend
        wrapProgram $out/bin/idris2-python \
          --suffix IDRIS2_LIBS ':' "$out/lib" \
          --suffix LIBRARY_PATH ':' "${pkgs.gmp}/lib" \
          --suffix C_INCLUDE_PATH ':' "${pkgs.gmp.dev}/include" \
          --set-default CC "${pkgs.clang}/bin/cc"
      '';
    };

    /* The following derivations are provided as examples, but are not to be provided in the build
      outputs of the derivation or repository.

      _idris2 = idrisPackage sources.idris2 {
      ipkgFile = "idris2.ipkg";
      idrisLibraries = [ network allPackages.idris2 ];
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
      idrisPackage sources.idris2 {
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
    "idris2-python"
  ];

  /* end of configuration section */
  inherit (builtins) elem mapAttrs;
  inherit (builders) idrisPackage useRuntimeLibs;

  builders = pkgs.callPackage ./builders
    {
      inherit idris2;
      inherit (sources) ipkg-to-json;
    }
    allPackages;

  allPackages =
    let
      primaryPackages = mapAttrs
        (name: src:
          let cfg = packageConfig."${name}" or { }; in
          idrisPackage src cfg)
        sources;
    in
    lib.recursiveUpdate primaryPackages extraPackages;
in
mapAttrs
  (name: pkg:
    if (elem name needRuntimeLibs) then (useRuntimeLibs pkg) else pkg)
  (lib.recursiveUpdate allPackages {
    _builders = builders;
    idris2 = useRuntimeLibs (lib.recursiveUpdate allPackages.idris2 idris2);
  })

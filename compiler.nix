{ lib
, stdenv
, makeWrapper
, clang
, chez
, racket
, gambit
, nodejs
, idris2-src
, gmp
, zsh

}:

# Uses scheme to bootstrap the build of idris2
let
  compiler = lib.makeOverridable stdenv.mkDerivation
    rec {
      pname = "idris2";
      version = "0.6.0";
      name = "${pname}-${version}";

      executable = "idris2";
      src = idris2-src;

      strictDeps = true;
      nativeBuildInputs = [ makeWrapper clang chez ]
        ++ lib.optional stdenv.isDarwin [ zsh ];
      buildInputs = [ chez gmp ];

      prePatch = ''
        patchShebangs --build tests
        sed 's/''$(GIT_SHA1)/${idris2-src.shortRev or "dirty"}/' -i Makefile
      '';

      makeFlags = [ "PREFIX=$(out)" ];

      # The name of the main executable of pkgs.chez is `scheme`
      buildFlags = [ "bootstrap" "SCHEME=scheme" ];

      checkInputs = [ gambit nodejs ]; # racket ];
      checkFlags = [ "INTERACTIVE=" ];
      outputs = [ "out" "support" ];

      postInstall = ''
        # Remove existing idris2 wrapper that sets incorrect LD_LIBRARY_PATH
        rm $out/bin/idris2

        # The only thing we need from idris2_app is the actual binary
        mv $out/bin/idris2_app/idris2.so $out/bin/idris2
        rm $out/bin/idris2_app/*
        rmdir $out/bin/idris2_app

        mkdir -p $support
        mv $out/${name}/ $support/

        # idris2 needs to find scheme at runtime to compile
        # idris2 installs packages with --install into the path given by
        #   IDRIS2_PREFIX. We set that to a default of ~/.idris2, to mirror the
        #   behaviour of the standard Makefile install.
        wrapProgram "$out/bin/idris2" \
          --set-default CHEZ "${chez}/bin/scheme" \
          --run 'export IDRIS2_PREFIX=''${IDRIS2_PREFIX-"$HOME/.idris2"}' \
          --suffix IDRIS2_LIBS ':' "$support/${name}/lib" \
          --suffix IDRIS2_DATA ':' "$support/${name}/support" \
          --suffix IDRIS2_PACKAGE_PATH ':' "$support/${name}" \
          --suffix DYLD_LIBRARY_PATH ':' "$support/${name}/lib" \
          --suffix LD_LIBRARY_PATH ':' "$support/${name}/lib"
      '';

      meta = {
        description = "A purely functional programming language with first class types";
        homepage = "https://github.com/idris-lang/Idris2";
        license = lib.licenses.bsd3;
        maintainers = with lib.maintainers; [ claymager ];
        inherit (chez.meta) platforms;
      };

      # for compatibility with withLibraries
      runtimeLibs = true;
    };

in
  /* We need one layer of indirection because `useRuntimeLibs` requires our own `.override`,
    not the one that comes from callPackage.
  */
{ c = compiler; }

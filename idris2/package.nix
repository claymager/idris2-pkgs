{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, clang
, chez
, racket
, gambit
, nodejs
, idris2-src
, gmp
, zsh

  # for compatability with extendWithPackages
, runtimeLibs ? true
}:

# Uses scheme to bootstrap the build of idris2
stdenv.mkDerivation rec {
  pname = "idris2";
  executable = pname;
  version = "0.4.0";

  src = idris2-src;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper clang chez ]
    ++ lib.optional stdenv.isDarwin [ zsh ];
  buildInputs = [ chez gmp ];

  prePatch = ''
    patchShebangs --build tests
    sed 's/''${GIT_SHA1}/${idris2-src.shortRev}/' -i Makefile
  '';

  makeFlags = [ "PREFIX=$(out)" ];

  # The name of the main executable of pkgs.chez is `scheme`
  buildFlags = [ "bootstrap" "SCHEME=scheme" ];

  checkInputs = [ gambit nodejs ]; # racket ];
  checkFlags = [ "INTERACTIVE=" ];

  # TODO: Move this into its own derivation, such that this can be changed
  #       without having to recompile idris2 every time.
  postInstall =
    let
      name = "${pname}-${version}";
    in
    ''
      # Remove existing idris2 wrapper that sets incorrect LD_LIBRARY_PATH
      rm $out/bin/idris2

      # The only thing we need from idris2_app is the actual binary
      mv $out/bin/idris2_app/idris2.so $out/bin/idris2
      rm $out/bin/idris2_app/*
      rmdir $out/bin/idris2_app

      # idris2 needs to find scheme at runtime to compile
      # idris2 installs packages with --install into the path given by
      #   IDRIS2_PREFIX. We set that to a default of ~/.idris2, to mirror the
      #   behaviour of the standard Makefile install.
      # TODO: Make libraries their own derivations to trim closure of extendWithPackages
      wrapProgram "$out/bin/idris2" \
        --set-default CHEZ "${chez}/bin/scheme" \
        --run 'export IDRIS2_PREFIX=''${IDRIS2_PREFIX-"$HOME/.idris2"}' \
        --suffix IDRIS2_LIBS ':' "$out/${name}/lib" \
        --suffix IDRIS2_DATA ':' "$out/${name}/support" \
        --suffix IDRIS2_PACKAGE_PATH ':' "$out/${name}" \
        --suffix LD_LIBRARY_PATH ':' "$out/${name}/lib"
    '';

  meta = {
    description = "A purely functional programming language with first class types";
    homepage = "https://github.com/idris-lang/Idris2";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ claymager ];
    inherit (chez.meta) platforms;
  };
}

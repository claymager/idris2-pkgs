{ stdenv, lib, makeWrapper, symlinkJoin, with-packages, idris2 }:

# # minimum requirements
{ name
, version ? "0.0"
, src

  # Idris-specific options
, idrisLibraries ? [ ]
, idrisTestLibraries ? [ ]
, codegen ? "chez"
, ipkgFile ? "${name}.ipkg"
, runtimeLibs ? false

  # accept other arguments
, doCheck ? false
, ...
} @ args:
let
  buildcommand = "idris2 --codegen ${codegen}";

  # A postBuild patch for every executable produced by the given codegen.
  #
  # Each entry is the body of a bash function with one argument:
  #   the relative path of the executable.
  patchCodegen = {
    chez = ''
      # No special treatment for Darwin: we don't have zsh in PATH.
      sed 's/Darwin/FakeSystem/' -i $1;

      # We don't need these anymore
      rm $1_app/compileChez $1_app/$(basename $1).ss
    '' + (if runtimeLibs then ''
      wrapProgram $1 \
        --set-default IDRIS2_PREFIX "~/.idris2"
        --suffix IDRIS2_PACKAGE_PATH ':' "${idris2}/${idris2.name}"
    '' else "");
  };

  setupCodegenPatch = ''
    patchCodegen () {
      ${patchCodegen.${codegen} or ""}
    }

    runPatchCodegen () {

      # We may need to call this more than once, so ignore any files passed as argument
      local ignoredFiles=
      for arg in $@; do
        ignoredFiles="$ignoredFiles ! -wholename $arg"
      done

      # Patch remaining executables in build/exec
      if [ -d build/exec ]; then
        export -f patchCodegen
        find build/exec \
          -maxdepth 1 -type f -executable \
         $ignoredFiles \
         -exec bash -c 'patchCodegen "$0"' {} \;
      fi
    }
  '';

  build = stdenv.mkDerivation (args // {
    name = "${name}-${version}";

    nativeBuildInputs =
      [ (with-packages idrisLibraries) makeWrapper ]
        ++ args.nativeBuildInputs or [ ];

    checkInputs =
      [ (with-packages (idrisLibraries ++ lib.optionals doCheck idrisTestLibraries)) ]
        ++ args.checkInptus or [ ];

    buildInputs = args.buildInputs or [ ];

    inherit setupCodegenPatch;
    buildPhase = args.buildPhase or ''
      runHook setupCodegenPatch
      runHook preBuild

      ${buildcommand} --build ${ipkgFile}
      runPatchCodegen

      runHook postBuild
    '';

    inherit doCheck;
    checkPhase = args.checkPhase or (
      let checkCommand = args.checkCommand or ''
        find . -maxdepth 2 -name test.ipkg -exec ${buildcommand} --build {} \;
      '';
      in
      ''
        runHook preCheck
        ignoreFiles=$(find build/exec -maxdepth 1 -type f -executable || true)

        # build test target
        ${checkCommand}

        runPatchCodegen $ignoreFiles
        runHook postCheck
      ''
    );

    installPhase = args.installPhase or ''
      runHook preBinInstall

      mkdir $out
      if [ "$(ls build/exec)"  ]; then
        mkdir -p $out/bin
        mv build/exec/* $out/bin
      else
        echo "build succeeded; no executable produced" > $out/${name}.out
      fi

      runHook postBinInstall
    '';

  });


  installLibrary =
    let
      thisLib = build.overrideAttrs
        (oldAttrs: {
          installPhase = ''
            runHook preLibInstall

            export IDRIS2_PREFIX=$out/
            mkdir -p $(idris2 --libdir)
            idris2 --install ${ipkgFile}

            runHook postLibInstall
          '';
        });
    in
    # If
      #  A depends on B, and
      #  B depends on C
      # Then
      #  Include A when building C
    symlinkJoin
      {
        inherit name;
        paths = [ thisLib ] ++ map (p: p.asLib) idrisLibraries;
      };

in

# `$ nix build .#mypkg` =>
  #     build/exec/main
  #   becomes
  #     $out/bin/main
  #
  # `$ nix build .#mypkg.asLib` =>
  #     build/ttc/mypkg-0.0/*
  #   becomes
  #     $out/idris2-0.3.0/mypkg-0.0/*
build // {
  asLib = installLibrary;
}

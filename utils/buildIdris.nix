{ stdenv, lib, makeWrapper, symlinkJoin, patchCodegen, with-packages, idris2 }:

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
, executable ? ""

  # accept other arguments
, doCheck ? false
, ...
} @ args:
let
  buildcommand = "${idris2.executable} --codegen ${codegen}";

  setupCodegenPatch = ''
    runPatchCodegen () {

      # We may need to call this more than once, so ignore any files passed as argument
      local ignoredFiles=
      for arg in $@; do
        ignoredFiles="$ignoredFiles ! -wholename $arg"
      done

      # Patch remaining executables in build/exec
      if [ -d build/exec ]; then
        find build/exec -maxdepth 1 -type f -executable $ignoredFiles \
          | while read file; do
              ${patchCodegen codegen}
            done;
      fi
    }
  '';

  forwardLibs =
    if runtimeLibs then ''
      find $out/bin -maxdepth 1 -type f -executable | while read file; do
         wrapProgram $file \
           --set-default IDRIS2_PREFIX "~/.idris2" \
           --suffix IDRIS2_PACKAGE_PATH ':' "${idris2}/${idris2.name}"
       done;
    '' else "";

  # Idris, and any packages needed to run tests
  testIdris = with-packages (idrisLibraries ++ lib.optionals doCheck idrisTestLibraries);

  build = stdenv.mkDerivation (args // {

    name = "${name}-${version}";

    nativeBuildInputs =
      [ (with-packages idrisLibraries) makeWrapper ]
        ++ args.nativeBuildInputs or [ ];

    checkInputs = [ testIdris ] ++ args.checkInputs or [ ];

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
    IDRIS2_PACKAGE_PATH = "${testIdris}/${idris2.name}";
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
        ${forwardLibs}
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
} // (if executable == "" then { } else { inherit executable; })

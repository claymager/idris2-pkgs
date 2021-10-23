{ stdenv, lib, makeWrapper, symlinkJoin, idrisCompiler, addLibraries, zsh }:

# # minimum requirements
{ name
, version ? "0.0"
, src

  # Idris-specific options
, idrisLibraries ? [ ]
, idrisTestLibraries ? [ ]
, codegen ? "chez"
, ipkgFile ? "${name}.ipkg"
, executable ? ""
, runtimeLibs ? false

  # accept other arguments
, doCheck ? false
, ...
} @ args:
let
  idris2 = idrisCompiler.compiler;

  buildcommand = "${idris2.executable} --codegen ${codegen}";

  # Idris, and any packages needed to run tests
  testIdris = addLibraries idris2 (idrisLibraries ++ lib.optionals doCheck idrisTestLibraries);

  build = stdenv.mkDerivation (args // {

    name = "${name}-${if version == null then "0.0" else version}";

    nativeBuildInputs =
      [ (addLibraries idris2 idrisLibraries) makeWrapper ]
        ++ lib.optional stdenv.isDarwin [ zsh ]
        ++ args.nativeBuildInputs or [ ];

    checkInputs = [ testIdris ] ++ args.checkInputs or [ ];

    buildPhase = args.buildPhase or ''
      runHook preBuild

      ${buildcommand} --build ${ipkgFile}

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

        # build test target
        ${checkCommand}

        runHook postCheck
      ''
    );

    installPhase =
      let
        forwardLibs =
          if runtimeLibs then ''
            wrapProgram $out/bin/${executable} \
              --set-default IDRIS2_PREFIX "~/.idris2" \
              --suffix LD_LIBRARY_PATH ':' "${idrisCompiler.support}/${idris2.name}/lib" \
              --suffix IDRIS2_LIBS ':' "${idrisCompiler.support}/${idris2.name}/lib" \
              --suffix IDRIS2_DATA ':' "${idrisCompiler.support}/${idris2.name}/support" \
          '' else "";
      in
        args.installPhase or ''
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


  installLibrary = withSource:
    let
      thisLib = build.overrideAttrs
        (oldAttrs: {
          installPhase = ''
            runHook preLibInstall

            export IDRIS2_PREFIX=$out/
            mkdir -p $(idris2 --libdir)
            idris2 --install${if withSource then "-with-src" else ""} ${ipkgFile}

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
        paths = [ thisLib ] ++ map (p: if withSource then p.withSource else p.asLib) idrisLibraries;
      };

  docs =
    build.overrideAttrs
      ({ name, ... }: {
        name = name + "-docs";
        buildPhase = ''
          runHook preDocBuild

          idris2 --mkdoc ${ipkgFile}

          runHook postDocBuild
        '';

        installPhase = ''
          runHook preDocInstall

          mkdir -p $out/doc/${name}
          mv build/docs/* $out/doc/${name}/

          runHook postDocBuild
        '';
      });

in

# `$ nix build .#mypkg` =>
  #     build/exec/main
  #   becomes
  #     $out/bin/main
  #
  # `$ nix build .#mypkg.asLib` =>
  #     build/ttc/mypkg-0.0/*
  #   becomes
  #     $out/idris2-0.4.0/mypkg-0.0/*
build // {
  asLib = installLibrary false;
  withSource = installLibrary true;
  docs = docs;
  allDocs = symlinkJoin { name = "idris2-docs"; paths = [ docs ] ++ map (p: p.docs) (idrisLibraries ++ idrisTestLibraries); };
  idrisAttrs = args;
} // (if executable == "" then { } else { inherit executable; })

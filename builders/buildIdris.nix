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
} @ cfg:
let
  idris2 = idrisCompiler.compiler;

  buildcommand = "${idris2.executable} --codegen ${codegen}";

  # Idris, and any packages needed to run tests
  testIdris = addLibraries idris2 (idrisLibraries ++ lib.optionals doCheck idrisTestLibraries);

  /* An intermediate derivation, which contains the source *and* the build products.

    Without this, each of `pkg`, `pkg.withSource`, `pkg.asLib`, and `pkg.docs` has to
    compile the project independently.
  */
  ttc = stdenv.mkDerivation (cfg // {

    name = "${name}-ttc-${if version == null then "0.0" else version}";

    nativeBuildInputs =
      [ (addLibraries idris2 idrisLibraries) makeWrapper ]
        ++ cfg.nativeBuildInputs or [ ];

    propagatedBuildInputs = lib.optional stdenv.isDarwin [ zsh ]
      ++ cfg.propagatedBuildInputs or [ ];

    checkInputs = [ testIdris ] ++ cfg.checkInputs or [ ];

    buildPhase = cfg.buildPhase or ''
      runHook preBuild

      ${buildcommand} --build ${ipkgFile}

      runHook postBuild
    '';

    inherit doCheck;
    checkPhase = cfg.checkPhase or (
      ''
        runHook preCheck

        # if there is a 'test.ipkg' near the project root, build it
        find . -maxdepth 2 -name test.ipkg -exec ${buildcommand} --build {} \;

        runHook postCheck
      ''
    );

    installPhase = ''
      # Cache everything for specialized builds
      mkdir $out/
      cp -r * $out/
    '';
  });

  # Primary output; the executable
  build = stdenv.mkDerivation (cfg // {

    name = "${name}-${if version == null then "0.0" else version}";
    src = ttc;
    inherit (ttc.drvAttrs) nativeBuildInputs propagatedBuildInputs;

    buildPhase = ''
      echo "${ttc.name} already built; doing nothing"
    '';

    installPhase = cfg.binInstallPhase or (
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
        cfg.installPhase or ''
          runHook preBinInstall

          mkdir $out
          # if there is something in build/exec, copy it to $out/bin
          if [ "$(ls build/exec)"  ]; then
            mkdir -p $out/bin
            mv build/exec/* $out/bin
            ${forwardLibs}
          else
            echo "build succeeded; no executable produced" > $out/${name}.out
          fi

          runHook postBinInstall
        ''
    );

  });

  # Library, for when something else depends on modules in this package
  installLibrary = withSource:
    let
      thisLib = build.overrideAttrs
        (_: {
          installPhase = ''
            runHook preLibInstall

            # Prepare the install location
            export IDRIS2_PREFIX=$out/
            mkdir -p $(idris2 --libdir)

            # Install
            idris2 --install${if withSource then "-with-src" else ""} ${ipkgFile}

            runHook postLibInstall
          '';
        });
    in
    # If (A < B) and (B < C); include A when buliding C
    symlinkJoin
      {
        inherit name;
        paths = [ thisLib ] ++ map (p: if withSource then p.withSource else p.asLib) idrisLibraries;
      };

  # Documenation output
  docs =
    build.overrideAttrs
      ({ name, ... }: {
        name = name + "-docs";
        buildPhase = cfg.docBuildPhase or ''
          runHook preDocBuild

          idris2 --mkdoc ${ipkgFile}

          runHook postDocBuild
        '';

        installPhase = cfg.docInstallPhase or ''
          runHook preDocInstall

          mkdir -p $out/doc/${name}
          mv build/docs/* $out/doc/${name}/

          runHook postDocInstall
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
  idrisAttrs = cfg;
} // (if executable == "" then { } else { inherit executable; })

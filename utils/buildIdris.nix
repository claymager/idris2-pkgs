{ stdenv, lib, makeWrapper, symlinkJoin, idris2, extendWithPackages, zsh }:

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

  # Idris, and any packages needed to run tests
  testIdris = extendWithPackages idris2 (idrisLibraries ++ lib.optionals doCheck idrisTestLibraries);

  build = stdenv.mkDerivation (args // {

    name = "${name}-${version}";

    nativeBuildInputs =
      [ (extendWithPackages idris2 idrisLibraries) makeWrapper ]
        ++ lib.optional stdenv.isDarwin [ zsh ]
        ++ args.nativeBuildInputs or [ ];

    checkInputs = [ testIdris ] ++ args.checkInputs or [ ];

    buildInputs = args.buildInputs or [ ];

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
              --suffix IDRIS2_PACKAGE_PATH ':' "${idris2}/${idris2.name}"
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
  #     $out/idris2-0.4.0/mypkg-0.0/*
build // {
  asLib = installLibrary;
} // (if executable == "" then { } else { inherit executable; })

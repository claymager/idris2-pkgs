{ stdenv, lib, symlinkJoin, with-packages }:

# # minimum requirements
{ name
, version ? "0.0"
, src

  # Idris-specific options
, idrisLibraries ? [ ]
, codegen ? "chez"
, ipkgFile ? "${name}.ipkg"

  # accept other arguments
, ...
} @ args:
let
  buildcommand = "idris2 --codegen ${codegen}";

  build = stdenv.mkDerivation (
    args // {

      name = "${name}-${version}";

      buildInputs = [ (with-packages idrisLibraries) ] ++ (args.buildInputs or [ ]);

      buildPhase = args.buildPhase or ''
        runHook preBuild

        ${buildcommand} --build ${ipkgFile}

        runHook postBuild
      '';

      doCheck = args.doCheck or false;
      checkPhase = args.checkPhase or (
        let checkCommand = args.checkCommand or ''
          if [ -e test.ipkg ]; then
            buildcommand} --build test.ipkg
          fi
        '';
        in
        ''
          # Locally install any new libraries
          export IDRIS2_PREFIX=build/env
          mkdir -p $(idris2 --libdir)
          ${buildcommand} --install ${ipkgFile}

          runHook preCheck

          # build test target
          ${checkCommand}

          runHook postCheck
        ''
      );

      installPhase = args.installPhase or ''
        runHook preBinInstall

        mkdir $out
        if [ -d build/exec ]; then
          mkdir -p $out/bin
          mv build/exec/* $out/bin
        else
          echo "build succeeded; no executable produced" > $out/${name}.out
        fi

        runHook postBinInstall
      '';

    }
  );


  installLibrary =
    let
      thisLib = build.overrideAttrs (oldAttrs: {
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
    symlinkJoin {
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
build // { asLib = installLibrary; }

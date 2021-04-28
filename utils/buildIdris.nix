{ stdenv
, lib
, name
, version
, src
, idris2
, symlinkJoin
, with-packages
, preBuild ? ""
, idrisLibraries ? [ ]
, extraBuildInputs ? [ ]
, ipkgName ? name + ".ipkg"
}:
let
  build = stdenv.mkDerivation {

    name = "${name}-${version}";

    inherit src;

    buildInputs = [ (with-packages idrisLibraries) ] ++ extraBuildInputs;

    buildPhase = ''
      ${preBuild}
      idris2 --build ${ipkgName}
    '';

    installPhase = ''
      mkdir $out
      if [ -d build/exec ]; then
        mkdir -p $out/bin
        mv build/exec/* $out/bin
      else
        echo "build succeeded; no executable produced" > $out/${name}.out
      fi
    '';
  };

  installLibrary =
    let
      thisLib = build.overrideAttrs (oldAttrs: {
        installPhase = ''
          mkdir -p $out/${idris2.name}
          export IDRIS2_PREFIX=$out/
          idris2 --install ${ipkgName}
        '';
      });
    in
    symlinkJoin {
      inherit name;
      paths = [ thisLib ] ++ map (p: p.asLib) idrisLibraries;
    };

in
build // { asLib = installLibrary; }

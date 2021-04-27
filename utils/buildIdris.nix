{ stdenv
, lib
, name
, src
, idris2
, symlinkJoin
, with-packages
, preBuild ? ""
, idrisLibraries ? [ ]
, extraBuildInputs ? [ ]
, ipkgName ? name + ".ipkg"
, version ? "0.0"
}:
let
  build = stdenv.mkDerivation {

    inherit name src version;

    buildInputs = [ (with-packages idrisLibraries) ] ++ extraBuildInputs;

    buildPhase = ''
      ${preBuild}
      idris2 --build ${ipkgName}
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv build/exec/* $out/bin
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

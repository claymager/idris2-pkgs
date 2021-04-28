{ lib, pkgs, buildIdris, packages, fetchFromGitHub }:

file:
let
  tomlPackage = (builtins.fromTOML (builtins.readFile file));

  toIdrisPackage = toml: lib.filterAttrs (n: v: v != null) {
    # (bare)
    name = toml.name;
    version = toml.version or null;
    codegen = toml.codegen or null;
    ipkgFile = toml.ipkgFile or null;

    # [ source ]
    src = fetchFromGitHub toml.source;

    # [ patch ]
    preBuild = toml.patch.preBuild or null;
    postBuild = toml.patch.postBuild or null;
    preBinInstall = toml.patch.preBinInstall or null;
    postBinInstall = toml.patch.postBinInstall or null;
    preLibInstall = toml.patch.preLibInstall or null;
    postLibInstall = toml.patch.postLibInstall or null;

    # [ test ]
    doCheck = toml.test.enable or null;
    checkCommand = toml.test.command or null;
    preCheck = toml.test.preTest or null;
    postCheck = toml.test.postTest or null;

    # [ Depends ]
    buildInputs = map (p: pkgs.${p}) (toml.depends.buildDeps or [ ]);
    idrisLibraries = map (p: packages.${p}) (toml.depends.idrisLibs or [ ]);

  };
in
buildIdris (toIdrisPackage tomlPackage)

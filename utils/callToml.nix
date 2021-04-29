{ lib, pkgs, buildIdris, ipkgs, fetchFromGitHub }:

let
  # loadTOML : File -> TomlDec
  loadTOML = file: builtins.fromTOML (builtins.readFile file);

  # cleanTOML : (SourceDec -> Source) -> TomlDec -> IdrisDec
  cleanTOML = fetchSource: toml: lib.filterAttrs (n: v: v != null) {
    # (bare)
    name = toml.name;
    version = toml.version or null;
    codegen = toml.codegen or null;
    ipkgFile = toml.ipkgFile or null;

    # [ source ]
    src = fetchSource toml.source;

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

    # [ depends ]
    buildInputs = map (p: pkgs.${p}) (toml.depends.buildDeps or [ ]);
    idrisLibraries = map (p: ipkgs.${p}) (toml.depends.idrisLibs or [ ]);

    # [ meta ]
    meta = toml.meta or { };

  };
in

{
  callTOML = file:
    buildIdris (cleanTOML fetchFromGitHub (loadTOML file));

  buildTOMLRepo = dir: file: 7;
}

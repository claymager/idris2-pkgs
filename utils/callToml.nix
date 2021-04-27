{ lib, pkgs, buildIdris, packages, fetchFromGitHub }:
file:
let
  defaults = {
    version = "0.0";
    depends.idrisDeps = [ ];
    depends.extraDeps = [ ];
  };

  tomlPackage = lib.recursiveUpdate defaults
    (builtins.fromTOML (builtins.readFile file));

  toIdrisPackage = toml: {
    inherit (toml) name version;
    src = fetchFromGitHub toml.source;
    extraBuildInputs = builtins.map (p: pkgs.${p}) toml.depends.extraDeps;
    idrisLibraries = builtins.map (p: packages.${p}) toml.depends.idrisDeps;
  };
in
buildIdris (toIdrisPackage tomlPackage)

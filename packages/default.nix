{ pkgs, lib, fetchFromGitHub, stdenv, idris2 }:
let
  with-packages = pkgs.callPackage ./with-packages.nix { inherit idris2; };

  buildIdris = args: pkgs.callPackage ./buildIdris.nix ({ inherit idris2 with-packages; } // args);

  callPackage = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  callTOML = file:
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
    buildIdris (toIdrisPackage tomlPackage);

  packages = rec {

    idris2api = callPackage ./idris2api.nix { inherit idris2; };

    readline-sample = callPackage ./readline-sample.nix { };

    comonad = callTOML ./comonad.toml;

    elab-util = callTOML ./elab-util.toml;

    sop = callTOML ./sop.toml;

    pretty-show = callTOML ./pretty-show.toml;

    hedgehog = callTOML ./hedgehog.toml;

  };


in
{
  inherit callPackage packages;

  withPackages = fn: with-packages (fn packages);
}

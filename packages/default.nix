{ pkgs, lib, fetchFromGitHub, stdenv, idris2 }:
let
  with-packages = pkgs.callPackage ./with-packages.nix { inherit idris2; };

  buildIdris = args: pkgs.callPackage ./buildIdris.nix ({ inherit idris2 with-packages; } // args);

  callPackage = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  callTOML = pkgs.callPackage ./callToml.nix { inherit buildIdris packages; };

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

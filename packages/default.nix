{ pkgs, lib, fetchFromGitHub, stdenv, idris2 }:
let
  with-packages = pkgs.callPackage ./with-packages.nix { inherit idris2; };

  buildIdris = args: pkgs.callPackage ./buildIdris.nix ({ inherit idris2 with-packages; } // args);

  callPackage = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

in
rec {
  inherit callPackage;

  packages = rec {
    comonad = callPackage ./comonad.nix { };
    elab-util = callPackage ./elab-util.nix { };
    sop = callPackage ./sop.nix { inherit elab-util; };

    readline = callPackage ./readline.nix { };
    with-ffi = callPackage ./with-ffi.nix { };
  };


  withPackages = fn: with-packages (fn packages);
}

{ lib, pkgs, idris2-src }:
let
  idris2 = pkgs.callPackage ./package.nix { inherit idris2-src; };
  utils = pkgs.callPackage ./../packages { inherit idris2; };
in
lib.recursiveUpdate idris2 utils

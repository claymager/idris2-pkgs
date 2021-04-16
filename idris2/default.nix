{ lib, pkgs } :
let
  idris2 = pkgs.callPackage ./package.nix {};
  utils = pkgs.callPackage ./../packages { inherit idris2; };
in
lib.recursiveUpdate idris2 utils

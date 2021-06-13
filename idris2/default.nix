{ lib, pkgs, idris2-src }:
let
  idris2 = pkgs.callPackage ./package.nix { inherit idris2-src; };
  utils = pkgs.callPackage ./../utils { inherit idris2; };
  packages = pkgs.callPackage ./../packages { inherit utils; };
in
lib.recursiveUpdate packages (packages.extendWithPackages idris2)

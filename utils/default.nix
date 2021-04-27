{ pkgs, lib, idris2 }:

let
  with-packages = pkgs.callPackage ./with-packages.nix { inherit idris2; };

  buildIdris = args: pkgs.callPackage ./buildIdris.nix ({ inherit idris2 with-packages; } // args);

  callPackage = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  builders = packages:
    {
      callTOML = pkgs.callPackage ./callToml.nix { inherit buildIdris packages; };
      callNix = callPackage;
      withPackages = fn: with-packages (fn packages);

    };
in
{
  inherit builders;
}


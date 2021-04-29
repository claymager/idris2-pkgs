{ pkgs, lib, idris2 }:

# IPkg is subtype of Derivation
let
  # with-packages : List IPkg -> Derivation
  with-packages = pkgs.callPackage ./with-packages.nix { inherit idris2; };

  # buildIdris : IdrisDec -> IPkg
  buildIdris = pkgs.callPackage ./buildIdris.nix { inherit with-packages; };

  # wrap callPackage with default buildIdris added to args
  callNix = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  buildFromTOML = ipkgs: pkgs.callPackage ./callToml.nix { inherit buildIdris ipkgs; };

in
{
  builders = ipkgs:
    {
      inherit (buildFromTOML ipkgs)
        callTOML#      # TOMLFile -> IPkg
        buildTOMLRepo; # PATH??? -> String -> Ipkg

      callNix = callNix; # IdrisDec -> Ipkg

      # withPackages : (Attrset IPkg -> List Ipkg) -> Derivation
      withPackages = fn: with-packages (fn ipkgs);
    };
}

{ pkgs, lib, idris2 }:

# IPkg is subtype of Derivation
let
  patchCodegen = import ./patchCodegen.nix;

  # with-packages : List IPkg -> Derivation
  with-packages-raw = pkgs.callPackage ./with-packages.nix { inherit idris2; };
  with-packages = with-packages-raw idris2;

  # buildIdris : IdrisDec -> IPkg
  buildIdris = lib.makeOverridable (pkgs.callPackage ./buildIdris.nix { inherit with-packages idris2 patchCodegen; });

  # callPackage, but it also knows about buildIdris
  callNix = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  buildFromTOML = ipkgs: pkgs.callPackage ./callToml.nix { inherit buildIdris ipkgs; };

in
{
  builders = ipkgs:
    let
      baseWithPackages = base: fn: with-packages-raw base (fn ipkgs);
    in

    {
      inherit (buildFromTOML ipkgs)
        callTOML#        # (toml : Path) -> IPkg
        buildTOMLSource; # (root : Path) -> (toml : Path) -> Ipkg

      callNix = callNix; # IdrisDec -> Ipkg

      # withPackages : (Attrset IPkg -> List Ipkg) -> Derivation
      withPackages = baseWithPackages idris2;

      extendWithLibs = pkg:
        pkg // { withPackages = baseWithPackages pkg; };
    };
}

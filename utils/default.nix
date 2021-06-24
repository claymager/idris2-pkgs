{ pkgs, lib, idris2 }:

# IPkg is subtype of Derivation
let
  # with-packages : List IPkg -> Derivation
  extendWithPackages = pkgs.callPackage ./with-packages.nix { inherit idris2; };

  # buildIdris : IdrisDec -> IPkg
  buildIdris = lib.makeOverridable (pkgs.callPackage ./buildIdris.nix
    { inherit idris2 extendWithPackages; });

  # callPackage, but it also knows about buildIdris
  callNix = file: args: pkgs.callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  buildFromTOML = ipkgs: pkgs.callPackage ./callToml.nix { inherit buildIdris ipkgs; };

in
{
  builders = ipkgs:
    {
      inherit (buildFromTOML ipkgs)
        callTOML#        # (toml : Path) -> IPkg
        buildTOMLSource; # (root : Path) -> (toml : Path) -> Ipkg

      callNix = callNix; # IdrisDec -> Ipkg

      extendWithPackages = pkg:
        let
          # If we can use TTC files, we almost certainly need Prelude, etc.
          pk = pkg.override { runtimeLibs = true; };
          add-libs = p: p // builtins.mapAttrs (name: lib: (add-libs (extendWithPackages p [ lib ]))) ipkgs;
        in
        pk // {
          # withPackages : (Attrset IPkg -> List Ipkg) -> Derivation
          withPackages = fn: extendWithPackages pk (fn ipkgs);
          withPkgs = add-libs pk;
        };
    };
}

{ callPackage, lib, idris2, renamePkgs, ipkg-to-json }:

# IPkg is subtype of Derivation
let

  # with-packages : List IPkg -> Derivation
  extendWithPackages = callPackage ./with-packages.nix { inherit idris2; };

  # buildIdris : IdrisDec -> IPkg
  buildIdris = lib.makeOverridable (callPackage ./buildIdris.nix
    { inherit idris2 extendWithPackages; });

  # callPackage, but it also knows about buildIdris
  callNix = file: args: callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  # buildIdrisRepo_ : Attrs IPkg -> Source -> Partial IdrisDec -> IPkg
  buildIdrisRepo_ = callNix ./buildRepo.nix { inherit renamePkgs ipkg-to-json; };

  buildFromTOML = ipkgs: callNix ./callToml.nix { inherit ipkgs; };

in
ipkgs:
{
  inherit buildIdris callNix;

  # idrisPackage : Source -> Partial IdrisDec -> IPkg
  idrisPackage = buildIdrisRepo_ ipkgs;

  inherit (buildFromTOML ipkgs)
    callTOML#        # (toml : Path) -> IPkg
    buildTOMLSource; # (root : Path) -> (toml : Path) -> Ipkg

  useRuntimeLibs = pkg:
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
}

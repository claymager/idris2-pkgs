{ callPackage, lib, idris2, renamePkgs, ipkg-to-json }:

# IPkg is subtype of Derivation
let

  # with-packages : (withSource : Bool) -> List IPkg -> Derivation
  extendWithPackages = callPackage ./with-packages.nix { inherit idris2; };

  # buildIdris : IdrisDec -> IPkg
  buildIdris = lib.makeOverridable (callPackage ./buildIdris.nix
    { inherit idris2; extendWithPackages = extendWithPackages false; });

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

  /* If an executable `pkg` needs to understand idris code at runtime, like the lsp or various backends,
    `useRuntimeLibs pkg` configure that correctly.
  */
  useRuntimeLibs = pkg:
    let
      # If we can use TTC files, we almost certainly need Prelude, etc.
      pk = pkg.override { runtimeLibs = true; };
      add-libs = withSource: p:
        p // builtins.mapAttrs
          (_: lib:
            (add-libs withSource (extendWithPackages withSource p [ lib ])))
          ipkgs;
    in
    pk // {
      # withPackages : (Attrset IPkg -> List Ipkg) -> Derivation
      withPackages = fn: extendWithPackages false pk (fn ipkgs);
      withSources = fn: extendWithPackages true pk (fn ipkgs);
      withPkgs = add-libs false pk;
      withSrcs = add-libs true pk;
    };
}

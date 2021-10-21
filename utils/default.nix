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
  useRuntimeLibs = pkg':
    let
      # If we can use TTC files, we almost certainly need Prelude, etc.
      pkg = extendWithPackages true pkg' [ ipkgs.prelude ipkgs.base ];

      /* recursive mess
        This allows us to build arbitrary chains of libraries, i.e.
        `lsp.withSrcs.comonad.hedgehog`
      */
      add-libs = withSource:
        let go = p:
          let extendWith = q: extendWithPackages withSource p [ q ]; in
          (builtins.mapAttrs
            (_: q: go (extendWith q))
            ipkgs) // p;
        in go;

    in
    pkg // rec {
      # withPackages : (Attrset IPkg -> List Ipkg) -> Derivation
      withLibraries = fn: extendWithPackages false pkg (fn ipkgs);
      withSources = fn: extendWithPackages true pkg (fn ipkgs);
      withPackages = lib.warn
        "DeprecationWarning: withPackages is deprecated in favor of withLibraries"
        withLibraries;

      withLibs = add-libs false pkg;
      withSrcs = add-libs true pkg;
      withPkgs = lib.warn
        "DeprecationWarning: withPkgs is deprecated in favor of withLibs"
        withLibs;
    };
}

{ callPackage, lib, symlinkJoin, python3, idrisCompiler, renamePkgs, ipkg-to-json }:

# IPkg is subtype of Derivation
let
  idris2 = idrisCompiler.compiler;

  # with-packages : (withSource : Bool) -> List IPkg -> Derivation
  inherit (callPackage ./with-packages.nix { inherit idris2; }) addSources addLibraries;

  # buildIdris : IdrisDec -> IPkg
  buildIdris = lib.makeOverridable (callPackage ./buildIdris.nix
    { inherit idrisCompiler addLibraries; });

  # callPackage, but it also knows about buildIdris
  callNix = file: args: callPackage file (lib.recursiveUpdate { inherit buildIdris; } args);

  # buildIdrisRepo_ : Attrs IPkg -> Source -> Partial IdrisDec -> IPkg
  buildIdrisRepo_ = callNix ./buildRepo.nix { inherit renamePkgs ipkg-to-json; };

  buildFromTOML = ipkgs: callNix ./callToml.nix { inherit ipkgs; };

in
ipkgs:
let
  /* If an executable `pkg` needs to understand idris code at runtime, like the lsp or various backends,
    `useRuntimeLibs pkg` configure that correctly.
  */
  useRuntimeLibs = pkg':
    let
      # If we can use TTC files, we almost certainly need Prelude, etc.
      pkg = addSources
        (pkg'.overrideAttrs (_: { runtimeLibs = true; })) [ ipkgs.prelude ipkgs.base ]
      // { inherit (pkg') asLib withSource; };

      # Corecursive mess, but it works
      # @p is package layer n
      # @q is package layer n+1
      also = extension:
        let go = p:
          let extendWith = q: extension p [ q ]; in
          (builtins.mapAttrs
            (_: q: go (extendWith q))
            ipkgs) // p;
        in go;

    in
    pkg // rec {
      # withPackages : (Attrset IPkg -> List Ipkg) -> Derivation
      withLibraries = fn: addLibraries pkg (fn ipkgs);
      withSources = fn: addSources pkg (fn ipkgs);
      withPackages = lib.warn
        "DeprecationWarning: withPackages is deprecated in favor of withLibraries"
        withLibraries;

      /* This allows us to build arbitrary chains of libraries, i.e.
        `lsp.withSrcs.comonad.hedgehog`
      */
      withLibs = also addLibraries pkg;
      withSrcs = also addSources pkg;
      withPkgs = lib.warn
        "DeprecationWarning: withPkgs is deprecated in favor of withLibs"
        withLibs;
    };
in
{
  inherit buildIdris callNix useRuntimeLibs;

  # idrisPackage : Source -> Partial IdrisDec -> IPkg
  idrisPackage = buildIdrisRepo_ ipkgs;

  inherit (buildFromTOML ipkgs)
    callTOML#        # (toml : Path) -> IPkg
    buildTOMLSource; # (root : Path) -> (toml : Path) -> Ipkg

  compiler = useRuntimeLibs idris2;
  devEnv = pkg:
    let ps = (pkg.idrisAttrs.idrisLibraries or [ ]) ++ (pkg.idrisAttrs.idrisTestLibraries or [ ]);
    in
    symlinkJoin {
      name = "idris2-env";
      paths = [
        (addSources idris2 ps)
        (addSources ipkgs.lsp ps)
      ] ++ map (p: p.docs) ps;
      postBuild = ''
        echo "#!/usr/bin/env sh" > $out/bin/docs-serve
        echo "${python3}/bin/python -m http.server --directory $out/share/doc \$argv" > $out/bin/docs-serve
        chmod 755 $out/bin/docs-serve
      '';
    };
}

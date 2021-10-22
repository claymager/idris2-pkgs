{ callPackage, buildIdris, lib, renamePkgs, ipkg-to-json }: basePkgs:
src: { extraLibs ? { }, ... }@args:
let

  inherit (builtins) match readDir readFile removeAttrs;
  inherit (lib.lists) any filter flatten findSingle;
  inherit (lib.attrsets) attrNames recursiveUpdate maybeAttr;
  inherit (lib.strings) hasSuffix;

  # ipkgToNix : (contents : String) -> Attrs*
  ipkgToNix = callPackage ./ipkg-to-nix.nix { inherit buildIdris; src = ipkg-to-json; };

  err = msg: throw "When configuring package for ${src}:\n${msg}";

  /* Loads data from (what it guesses is) the primary .ipkg */
  ipkgFile = args.ipkgFile or (
    let
      ipkgFiles = flatten (filter (x: x != null)
        (map (match "(.*)\\.ipkg") (attrNames (readDir src))));
      /* It is common to include  something like `mypkg-docs.ipkg` at the toplevel.
        We want to ignore such a file, unless specified otherwise. */
      ignored = [ "test" "tests" "doc" "docs" ];
      notIgnored = fn: !any (pat: hasSuffix pat fn) ignored;
      main = findSingle
        notIgnored
        (err "No valid *.ipkg file found")
        (err "Multiple valid *.ipkg files found")
        ipkgFiles;
    in
    main + ".ipkg"
  );

  ipkgData = ipkgToNix (readFile (src + "/${ipkgFile}"));

  # chooseFrom : Attrs Packages -> List String -> List Pacakges
  chooseFrom = ps: depends:
    let
      extraPkgs = args.extraPkgs or { };
      allPkgs = recursiveUpdate ps extraPkgs;
      savedPkgNames = attrNames extraPkgs;

      /* TODO: renameDeps is just using attrset lookup as a map, where the keys are
        "idris2 package" names and the values are `idris2-pkgs` names.

        However, unicode compatibility issues are likely here: idris2 supports unicode
        package names, while nix does not allow unicode in keys.
      */
      renameDeps = dep: maybeAttr dep.name dep.name (
        removeAttrs renamePkgs savedPkgNames
      );
      depNames = map renameDeps depends;
    in
    map (d: maybeAttr (err "Unknown idris package ${d}") d allPkgs) depNames;

in
buildIdris ({
  inherit src;
  inherit (ipkgData) name version;
  idrisLibraries = chooseFrom basePkgs ipkgData.depends;
  executable = ipkgData.executable or "";
} // args)

{ callPackage, buildIdris, lib, renamePkgs, ipkg-to-json }: basePkgs:
src: { extraPkgs ? { }, ... }@args:
let
  inherit (builtins) match attrNames readDir readFile any
    elem filter removeAttrs getAttr mapAttrs;
  inherit (lib.lists) sort length head findSingle;
  inherit (lib) subtractLists recursiveUpdate maybeAttr;

  # ipkgToNix : (contents : String) -> Attrs*
  ipkgToNix = callPackage ./ipkg-to-nix.nix { inherit buildIdris; src = ipkg-to-json; };

  choosePkgs = ps: extraPkgs: depends:
    let
      ipkgs = recursiveUpdate ps extraPkgs;
      savedPkgNames = attrNames extraPkgs;
      notDefault = p: !(elem p (subtractLists savedPkgNames [ "network" "test" "contrib" "base" "prelude" ]));
      pkgNames = removeAttrs renamePkgs savedPkgNames;
      renameDeps = dep: maybeAttr dep dep pkgNames;
      depNames = map renameDeps (filter notDefault (map (d: d.name) depends));
    in
    map (d: maybeAttr (throw "Unknown idris package ${d}") d ipkgs) depNames;


  pkgmap = choosePkgs basePkgs;

  err = msg: throw "When configuring package for ${src}:\n${msg}";

  /* Loads data from (what it guesses is) the primary .ipkg */
  ipkg = args.ipkgFile or (
    let
      allIpkgs = lib.lists.flatten (filter (x: x != null)
        (map (match "(.*)\\.ipkg") (attrNames (readDir src))));
      /* It is common to include  something like `mypkg-docs.ipkg` at the toplevel.
        We want to ignore such a file, unless specified otherwise. */
      ignored = [ "test" "tests" "doc" "docs" ];
      notIgnored = fn: !any (pat: lib.strings.hasSuffix pat fn) ignored;
      main = findSingle
        notIgnored
        (err "No valid *.ipkg file found")
        (err "Multiple valid *.ipkg files found")
        allIpkgs;
    in
    main + ".ipkg"
  );

  ipkgData = ipkgToNix (readFile (src + "/${ipkg}"));

in
buildIdris ({
  inherit src;
  inherit (ipkgData) name version;
  idrisLibraries = pkgmap extraPkgs ipkgData.depends;
  executable = ipkgData.executable or "";
} // args)

{ buildIdris, ipkgToNix, lib }: src: args:
let
  inherit (builtins) filter match attrNames readDir readFile removeAttrs any;
  inherit (lib.lists) sort length head findSingle;

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
  executable = ipkgData.executable or "";
} // args)

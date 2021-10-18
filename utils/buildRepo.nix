{ buildIdris, ipkgToNix, lib }: src: args:
let
  inherit (builtins) filter match attrNames readDir any;
  inherit (lib.lists) sort length head findSingle;

  err = msg: throw "When configuring package for ${src}:\n${msg}";

  /* Loads data from (what it guesses is) the primary .ipkg */
  mainIpkg =
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
    ipkgToNix (builtins.readFile (src + "/${main}.ipkg"));
in

buildIdris ({
  inherit src;
  inherit (mainIpkg) name version;
} // args)

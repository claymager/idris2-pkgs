{ buildIdris, lib }: src: args:
let
  inherit (builtins) filter match attrNames readDir any;
  inherit (lib.lists) sort length head findSingle;
  err = msg: throw "When configuring package for ${src}:\n${msg}";

  /* Gets a `name`, the basename of the file. */
  name =
    let
      allIpkgs = lib.lists.flatten (filter (x: x != null)
        (map (match "(.*)\.ipkg") (attrNames (readDir src))));

      /* It is common to include  something like `mypkg-docs.ipkg` at the toplevel.
        We want to ignore such a file, unless specified otherwise. */
      ignored = [ "test" "tests" "doc" "docs" ];
      notIgnored = fn: !any (pat: lib.strings.hasSuffix pat fn) ignored;
    in
    findSingle
      notIgnored
      (err "No valid *.ipkg file found")
      (err "Multiple valid *.ipkg files found")
      allIpkgs;
  rev = src.shortRev or (builtins.substring 0 7 (src.rev or "dirty"));
in
buildIdris ({ inherit src name; version = rev; } // args)

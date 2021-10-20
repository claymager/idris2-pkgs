let
  attrsets = {

    /* Like builtins.getAttr, but with a default value

      Example:
      x = { a = 42; }
      maybeAttr 0 "a" x
      => 42
      maybeAttr 0 "b" x
      => 0
    */
    maybeAttr = def: name: attrs:
      attrs."${name}" or def;
  };

  maintainers = {
    /* same format as NixOS maintainers-list.nix */
    claymager = {
      name = "John Mager";
      email = "jmageriii@gmail.com";
      github = "claymager";
      githubId = 8852150;
    };
  };

in
attrsets // { inherit attrsets maintainers; }

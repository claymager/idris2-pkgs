let attrsets = {

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

in attrsets // { inherit attrsets; }

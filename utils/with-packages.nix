# Build a version of idris with a set of idris packages
{ lib, idris2, symlinkJoin, makeWrapper, writeScriptBin }:

base: # Derivation; something like `idris2` or `lsp`
packages: # List Ipkg

lib.appendToName "with-packages" (symlinkJoin {
  inherit (base) name executable;

  paths = map (p: p.asLib) packages ++ [ base ];

  buildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram "$out/bin/${base.executable}" \
      --suffix IDRIS2_PACKAGE_PATH ':' "$out/${idris2.name}"
  '';

})

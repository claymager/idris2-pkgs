# Build a version of idris with a set of idris packages
{ lib, idris2, symlinkJoin, makeWrapper, writeScriptBin }:

let
  with-packages = withSource: # Bool
    base: # Derivation; something like `idris2` or `lsp`
    packages: # List Ipkg

    lib.appendToName "with-packages" (symlinkJoin {
      inherit (base) name executable;

      paths = map (p: if withSource then p.withSource else p.asLib) packages ++ [ base ];

      buildInputs = [ makeWrapper ];

      postBuild = ''
        wrapProgram "$out/bin/${base.executable}" \
          --suffix IDRIS2_PACKAGE_PATH ':' "$out/${idris2.name}"
      '';

      # nix run determines the binary to run first looking for meta.mainProgram
      # and falling back to the package name. with-packages changes the name, breaking
      # the heuristic that worked for the original package. We fix this by setting
      # meta.mainProgram (if not set already)
      meta =
        base.meta //
        lib.attrsets.optionalAttrs (base.meta ? mainProgram || base ? executable) {
          mainProgram = base.meta.mainProgram or base.executable;
        };

    });
in
{
  addLibraries = with-packages false;
  addSources = with-packages true;
}


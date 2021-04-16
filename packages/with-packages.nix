# Build a version of idris with a set of idris packages
{ lib, idris2, symlinkJoin, makeWrapper }: packages:

lib.appendToName "-with-packages" (symlinkJoin {

  inherit (idris2) name;

  paths = map (p: p.asLib) packages ++ [ idris2 ];

  buildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram "$out/bin/idris2" \
      --run "export IDRIS2_PACKAGE_PATH=$out/${idris2.name}:\$IDRIS2_PACKAGE_PATH" \
  '';

})

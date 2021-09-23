{ buildIdris, idris2, fetchFromGitHub, readline }:

buildIdris {

  name = "idris2api";

  inherit (idris2) src version;

  preBuild = ''
    echo 'module IdrisPaths' >> src/IdrisPaths.idr
    echo 'export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = ((${builtins.replaceStrings ["."] [","] idris2.version}), "${idris2.src.rev}")' >> src/IdrisPaths.idr
    echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
  '';
}

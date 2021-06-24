{ buildIdris, idris2, fetchFromGitHub, readline }:

buildIdris {

  name = "idris2api";

  inherit (idris2) src version;

  preBuild = ''
    echo 'module IdrisPaths' >> src/IdrisPaths.idr
    echo 'export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = ((0,4,0), "${idris2.src.rev}")' >> src/IdrisPaths.idr
    echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
  '';
}

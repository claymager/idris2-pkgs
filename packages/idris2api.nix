{ buildIdris, fetchFromGitHub, readline }:
let rev = "f255026d1b99934f4418993517eee11c8de8b678";
in
buildIdris {

  name = "idris2api";


  src = fetchFromGitHub {
    owner = "idris-lang";
    repo = "Idris2";
    inherit rev;
    sha256 = "h7CfQliuH9RnQZ3hrDta3thXqzCMapEIcuqUm4Xdzy8=";
  };

  preBuild = ''
    echo 'module IdrisPaths' >> src/IdrisPaths.idr
    echo 'export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = ((0,3,0), "${rev}")' >> src/IdrisPaths.idr
    echo 'export yprefix : String; yprefix="$(out)"' >> src/IdrisPaths.idr
  '';
}

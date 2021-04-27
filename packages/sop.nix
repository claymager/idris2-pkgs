{ buildIdris, fetchFromGitHub, elab-util }:

buildIdris {

  name = "sop";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-sop";
    rev = "469c7c584d4684d0059489ab2ac692904e9eb951";
    sha256 = "ry2QlfFNII6n34/ZjdKIZtFti3PXnPdmsd5e/vUVyKY=";
  };

  idrisLibraries = [ elab-util ];
}

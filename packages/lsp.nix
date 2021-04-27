{ buildIdris
, fetchFromGitHub
, idris2api
, lib
}:

buildIdris {

  name = "lsp";
  version = "0.0";

  idrisLibraries = [ idris2api ];

  src = fetchFromGitHub {
    owner = "idris-community";
    repo = "idris2-lsp";
    rev = "63e614776db3accebbcf4b64ac7a76e66e233e64";
    sha256 = lib.fakeHash;
  };

}

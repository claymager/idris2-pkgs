{ buildIdris
, fetchFromGitHub
, elab-util
, pretty-show
, sop
}:

buildIdris {
  name = "hedgehog";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-hedgehog";
    rev = "929b27c4a58111b4d1327abb18a2eee4ad304f48";
    sha256 = "Ev9LldllXHciUNHU8CcXrciW1WdxN8iW3J0kJwjsqjI=";
  };

  idrisLibraries = [ elab-util sop pretty-show ];
}

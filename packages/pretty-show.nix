{ buildIdris
, fetchFromGitHub
, elab-util
, sop
}:

buildIdris {
  name = "pretty-show";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-pretty-show";
    rev = "28d83af17c7f281cf49e593d4283d1b877788231";
    sha256 = "gOLFijoE7zJVlbPAlwMLLy/fYTE4++CQAQjsfd9EisY=";
  };

  idrisLibraries = [ elab-util sop ];

}

{ buildIdris, fetchFromGitHub, elab-util }:

buildIdris {

  name = "sop";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-sop";
    rev = "c6ca335f7bd26c3c9c53ad0b34910a5a3152f058";
    sha256 = "lD7XBlVGTTrUYuW2i2In1xkE1PAxKC9NnR3+2by1zAU=";
  };

  idrisLibraries = [ elab-util ];
}

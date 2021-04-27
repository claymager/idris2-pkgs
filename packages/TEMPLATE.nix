{ buildIdris
, fetchFromGitHub
, lib
, # Idris dependencies
  # elab-util,

  # Foreign dependencies
  # clang,
}:

buildIdris {

  # package name
  name = "MYPACKAGE";
  # version =  "0.0";

  # Commands to run before building
  # preBuild = ''
  # '';

  # idrisLibraries = [ elab-util ];

  # Foreign dependencies
  # extraBuildInputs = [ clang ];

  src = fetchFromGitHub {
    owner = "idris-lang";
    repo = "Idris2";
    rev = "";
    sha256 = lib.fakeHash;
  };

}

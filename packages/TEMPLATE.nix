{ buildIdris
, fetchFromGitHub
, # Idris dependencies
  #elab-util,

  # Outside dependencies
  #clang
}:

buildIdris {

  # package name
  name = "MYPACKAGE";

  # commands to run before building
  # preBuild = ''
  # '';

  # Outside dependencies
  # extraBuildInputs = [ clang ];

  src = fetchFromGitHub {
    # owner = "idris-lang";
    # repo = "Idris2";
    # rev = "";
    # sha256 = "";
  };

}

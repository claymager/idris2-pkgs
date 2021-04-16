{ buildIdris, fetchFromGitHub }:

buildIdris {

  name = "comonad";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-comonad";
    rev = "9bc8ae122160231b6c387e86bae0a34f34f678eb";
    sha256 = "uJjGvZnmftkl4bwTXN9aOAXPEjsz/8QxHvyeA/gjDaw=";
  };

}

{ buildIdris, fetchFromGitHub }:

buildIdris {

  name = "elab-util";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-elab-util";
    rev = "f3f1ff2a2d5558ee8217732e06b0e20a10fb7b3a";
    sha256 = "i+Bhw6GR1HDZ9imp8eNTGvBuNsIiKX+ZQu3apUqXxsw=";
  };

}

{ buildIdris, fetchFromGitHub, readline }:
buildIdris {

  name = "idris2api";

  src = fetchFromGitHub {
    owner = "idris-lang";
    repo = "Idris2";
    rev = "f255026d1b99934f4418993517eee11c8de8b678";
    sha256 = "h7CfQliuH9RnQZ3hrDta3thXqzCMapEIcuqUm4Xdzy8=";
  };
}

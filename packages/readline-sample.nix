{ buildIdris, fetchFromGitHub, readline }:
let
  repo = fetchFromGitHub {
    owner = "idris-lang";
    repo = "Idris2";
    rev = "f255026d1b99934f4418993517eee11c8de8b678";
    sha256 = "h7CfQliuH9RnQZ3hrDta3thXqzCMapEIcuqUm4Xdzy8=";
  };

in
buildIdris {

  name = "readline";

  extraBuildInputs = [ readline ];

  src = "${repo}/samples/FFI-readline";

}

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

  preBuild = ''
    # We don't have access to the greater repo
    sed -i 's/^include.*//' readline_glue/Makefile

    # Include stdio.h before readline.h
    sed -i 's/^\(#include <readline\)/#include <stdio.h>\n\1/' readline_glue/idris_readline.c
  '';

  extraBuildInputs = [ readline ];

  src = "${repo}/samples/FFI-readline";

}

{ lib, buildIdris, src, stdenv, writeText }:
let
  inherit (builtins) fromJSON readFile;
  executable = buildIdris {
    name = "ipkg-to-json";
    version = "0.1";
    inherit src;
  };

  ipkgToNix = file:
    let
      drv = stdenv.mkDerivation {
        name = "idris-package.json";
        buildCommand = ''
          ipkg-to-json ${file} > $out
        '';
        buildInputs = [ executable ];
      };

      outContents = readFile drv;
    in
    if (lib.strings.hasPrefix "Parse" outContents)
    then (throw "ParseError on input ipkg file:\n${file}")
    else
      fromJSON outContents;
in
ipkgToNix

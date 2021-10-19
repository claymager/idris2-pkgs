{ buildIdris, src, stdenv, writeText }:
let
  inherit (builtins) fromJSON readFile;
  executable = buildIdris {
    name = "ipkg-to-json";
    version = "0.1";
    inherit src;
  };

  ipkgToNix = code:
    let
      file = writeText "ipkg-contents" code;

      drv = stdenv.mkDerivation {
        name = "idris-package.json";
        buildCommand = ''
          ipkg-to-json ${file} > $out
        '';
        buildInputs = [ executable ];
      };
    in
    fromJSON (readFile drv);
in
ipkgToNix

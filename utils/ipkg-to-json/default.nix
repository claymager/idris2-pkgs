{ buildIdris, src, stdenv, writeText }:
let
  executable = buildIdris {
    name = "ipkg-to-json";
    version = "0.1";
    inherit src;
  };

  ipkgToNix = code:
    let
      file = writeText "ipkg-contents" code;

      drv = builtins.trace "calling on ${builtins.readFile file}" stdenv.mkDerivation {
        name = "idris-package.json";
        buildCommand = ''
          ipkg-to-json ${file} > $out
        '';
        buildInputs = [ executable ];
      };
    in
    builtins.fromJSON (builtins.readFile drv);
in
ipkgToNix

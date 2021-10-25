# List of all derivations produced by this repository
# Built with CI
let
  flk = builtins.getFlake (builtins.toString ./.);
  pkgs = flk.packages."${builtins.currentSystem}";
  noLibs = [ "inigo" ];
  packageParts = name: drv: [ drv drv.docs ] ++
    (if (builtins.elem name noLibs)
    then [ ]
    else [ drv.withSource drv.asLib ]);

in
builtins.attrValues (builtins.mapAttrs packageParts pkgs)

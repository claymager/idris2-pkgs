# List of all derivations produced by this repository
# Built with CI
let
  flk = builtins.getFlake (builtins.toString ./.);
  pkgs = builtins.removeAttrs flk.packages."${builtins.currentSystem}" [ "_builders" ];
  noLibs = [ "inigo" ];
  packageParts = name: drv: [ drv drv.docs ] ++
    (if (builtins.elem name noLibs)
    then [ ]
    else [ drv.withSource drv.asLib ]);

in
builtins.attrValues (builtins.mapAttrs packageParts pkgs)

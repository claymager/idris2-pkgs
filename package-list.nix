{ buildIdris, callPackage, srcs }:
let
  # utils
  ipkgToNix = callPackage ./utils/ipkg-to-json { inherit buildIdris; src = srcs.ipkg-to-json; };
  buildIdrisRepo = callPackage utils/buildRepo.nix { inherit buildIdris ipkgToNix; };
in
rec {
  idris2api = buildIdrisRepo srcs.idris2-src {
    ipkgFile = "idris2api.ipkg";
    name = "idris2api";
    preBuild = ''
      LONG_VERSION=$(idris2 --version)
      ARR=($(echo $LONG_VERSION | sed 's/-/ /g; s/\./,/g' ))
      VERSION="((''${ARR[-2]}), \"${srcs.idris2-src.shortRev}\")"

      echo 'module IdrisPaths' >> src/IdrisPaths.idr
      echo "export idrisVersion : ((Nat,Nat,Nat), String); idrisVersion = $VERSION" >> src/IdrisPaths.idr
      echo 'export yprefix : String; yprefix="~/.idris2"' >> src/IdrisPaths.idr
    '';
  };
  dom = buildIdrisRepo srcs.dom { idrisLibraries = [ elab-util sop ]; ipkgFile = "dom.ipkg"; };
  elab-util = buildIdrisRepo srcs.elab-util { };
  lsp = buildIdrisRepo srcs.lsp { idrisLibraries = [ idris2api ]; runtimeLibs = true; };
  idrall = buildIdrisRepo srcs.idrall { };
  sop = buildIdrisRepo srcs.sop { idrisLibraries = [ elab-util ]; };
  pretty-show = buildIdrisRepo srcs.pretty-show { idrisLibraries = [ sop elab-util ]; };
  hedgehog = buildIdrisRepo srcs.hedgehog { idrisLibraries = [ sop elab-util pretty-show ]; };
}

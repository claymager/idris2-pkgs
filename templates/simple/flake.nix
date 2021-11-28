{
  description = "My Idris 2 package";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    idris2-pkgs.url = "github:claymager/idris2-pkgs";
    nixpkgs.follows = "idris2-pkgs/nixpkgs";
  };

  outputs = { self, nixpkgs, idris2-pkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" "i686-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
        inherit (pkgs.idris2-pkgs._builders) idrisPackage devEnv;
        mypkg = idrisPackage ./. { };
        runTests = idrisPackage ./test { extraPkgs.mypkg = mypkg; };
      in
      {
        defaultPackage = mypkg;

        packages = { inherit mypkg runTests; };

        devShell = pkgs.mkShell {
          buildInputs = [ (devEnv mypkg) ];
        };
      }
    );
}

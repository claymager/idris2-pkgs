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
        inherit (idris2-pkgs.packages.${system}._builders) idrisPackage;

        # Local paths work within a git repository.
        # Otherwise, use one of
        # - an absolute path and the `--impure` build flag
        # - adding the source to `inputs`
        foo = idrisPackage ../library { };
        mypkg = idrisPackage ./. { extraPkgs.foo = foo; };
      in
      {
        defaultPackage = mypkg;
        packages = { inherit mypkg foo; };
      });
}

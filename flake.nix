{
  description = "A very basic flake";

  inputs.idris2-src = {
    url = github:idris-lang/idris2;
    flake = false;
  };

  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, idris2-src, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = import nixpkgs {inherit system;};
          idris2 = pkgs.callPackage ./idris2 { };
      in
      {

        devShell = pkgs.mkShell {
          buildInputs = [
            (idris2.withPkgs (ps: [ ps.comonad ]) )
            pkgs.nixpkgs-fmt
          ];
        };

      }
    );
}

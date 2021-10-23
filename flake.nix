{
  description = "Idris2 and its packages";

  inputs = {
    idris2-src = { url = "github:idris-lang/idris2/0a29d06f"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";

    comonad = { url = "github:stefan-hoeck/idris2-comonad"; flake = false; };
    dom = { url = "github:stefan-hoeck/idris2-dom"; flake = false; };
    elab-util = { url = "github:stefan-hoeck/idris2-elab-util"; flake = false; };
    hedgehog = { url = "github:stefan-hoeck/idris2-hedgehog"; flake = false; };
    idrall = { url = "github:alexhumphreys/idrall"; flake = false; };
    ipkg-to-json = { url = "github:claymager/ipkg-to-json"; flake = false; };
    inigo = { url = "github:idris-community/Inigo"; flake = false; };
    lsp = { url = "github:idris-community/idris2-lsp"; flake = false; };
    frex = { url = "github:frex-project/idris-frex"; flake = false; };
    pretty-show = { url = "github:stefan-hoeck/idris2-pretty-show"; flake = false; };
    sop = { url = "github:stefan-hoeck/idris2-sop"; flake = false; };

  };

  outputs = { self, nixpkgs, idris2-src, flake-utils, ... }@srcs:
    let
      inherit (builtins) removeAttrs mapAttrs;
      build-idris2-pkgs = import ./packageSet.nix {
        sources = removeAttrs srcs [ "self" "nixpkgs" "flake-utils" "idris2-src" ] // { idris2api = idris2-src; };
        lib = nixpkgs.lib.recursiveUpdate nixpkgs.lib (import ./lib);
      };
    in
    {
      overlay = final: prev:
        let
          compiler = final.callPackage ./compiler.nix { inherit idris2-src; };

          idris2-pkgs = build-idris2-pkgs final compiler
          // {
            idris2 = idris2-pkgs._builders.useRuntimeLibs compiler.compiler;
            _build-idris2-pkgs = build-idris2-pkgs final.callPackage;
          };
        in
        {
          inherit idris2-pkgs;
          idris2 = idris2-pkgs.idris2;

          lib = prev.lib.recursiveUpdate prev.lib (import ./lib);

        };

      templates = import ./templates;
    } //

    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
          packages = removeAttrs pkgs.idris2-pkgs [ "_builders" "_build-idris2-pkgs" ];
        in
        {
          inherit packages;

          defaultPackage = pkgs.idris2-pkgs.idris2;

          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };

          /* `$ nix flake check` (and `.. show`) require configured build machines for all systems
            supported by `idris2-pkgs`. This is due to ipkgToNix, which needs to execute on each
            system to read the derivation for each package there.

            `$ nix-build --no-out-links -A checks.CURRENT_SYSTEM` behaves as expected, and is used in the CI.
          */
          checks = packages // {
            lspWithPackages = packages.lsp.withLibraries (ps: [ ps.comonad ]);
          };

        }
      );

}

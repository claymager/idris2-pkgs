{
  description = "Idris2 and its packages";

  inputs = {
    idris2 = { url = "github:idris-lang/idris2"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";

    comonad = { url = "github:stefan-hoeck/idris2-comonad"; flake = false; };
    collie = { url = "github:ohad/collie"; flake = false; };
    katla = { url = "github:idris-community/katla"; flake = false; };
    dot-parse = { url = "github:CodingCellist/idris2-dot-parse"; flake = false; };
    dom = { url = "github:stefan-hoeck/idris2-dom"; flake = false; };
    elab-util = { url = "github:stefan-hoeck/idris2-elab-util"; flake = false; };
    effect = { url = "github:russoul/idris2-effect"; flake = false; };
    hedgehog = { url = "github:stefan-hoeck/idris2-hedgehog"; flake = false; };
    fvect = { url = "github:mattpolzin/idris-fvect"; flake = false; };
    idrall = { url = "github:alexhumphreys/idrall"; flake = false; };
    ipkg-to-json = { url = "github:claymager/ipkg-to-json"; flake = false; };
    inigo = { url = "github:idris-community/Inigo"; flake = false; };
    lsp = { url = "github:idris-community/idris2-lsp"; flake = false; };
    frex = { url = "github:frex-project/idris-frex"; flake = false; };
    json = { url = "github:stefan-hoeck/idris2-json"; flake = false; };
    Prettier = { url = "github:Z-snails/prettier"; flake = false; };
    pretty-show = { url = "github:stefan-hoeck/idris2-pretty-show"; flake = false; };
    sop = { url = "github:stefan-hoeck/idris2-sop"; flake = false; };

  };

  outputs = { self, nixpkgs, idris2, flake-utils, ... }@srcs:
    let
      inherit (builtins) removeAttrs mapAttrs;
      inherit (nixpkgs.lib) recursiveUpdate;
      build-idris2-pkgs = import ./packageSet.nix {
        sources = removeAttrs srcs [ "self" "nixpkgs" "flake-utils" ];
        lib = recursiveUpdate nixpkgs.lib (import ./lib);
      };
    in
    rec {
      overlay = final: prev:
        let
          compiler = final.callPackage ./compiler.nix { idris2-src = idris2; };

          idris2-pkgs =
            let ipkgs = build-idris2-pkgs final compiler;
            in
            recursiveUpdate ipkgs
              {
                idris2 = (ipkgs._builders.useRuntimeLibs compiler.compiler) // {
                  inherit (ipkgs.idris2) asLib withSource docs;
                };
                _builders.build-idris2-pkgs = build-idris2-pkgs final;
              };
        in
        {
          inherit idris2-pkgs;
          idris2 = idris2-pkgs.idris2;

          lib = recursiveUpdate prev.lib (import ./lib);

        };

      templates = import ./templates;
      defaultTemplate = templates.simple;
    } //

    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
        in
        {
          packages = pkgs.idris2-pkgs;

          defaultPackage = pkgs.idris2-pkgs.idris2;

          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };

        }
      );

}

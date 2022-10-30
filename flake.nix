{
  description = "Idris2 and its packages";

  inputs = {
    idris2 = { url = "github:idris-lang/idris2"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-21.11-darwin";

    comonad = { url = "github:stefan-hoeck/idris2-comonad"; flake = false; };
    collie = { url = "github:ohad/collie"; flake = false; };
    python = { url = "github:madman-bob/idris2-python"; flake = false; };
    odf = { url = "github:madman-bob/idris2-odf"; flake = false; };
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
    rhone = { url = "github:stefan-hoeck/idris2-rhone"; flake = false; };
    rhone-js = { url = "github:stefan-hoeck/idris2-rhone-js"; flake = false; };
    tailrec = { url = "github:stefan-hoeck/idris2-tailrec"; flake = false; };
    recombine = { url = "gitlab:avidela/recombine"; flake = false; };
    xml = { url = "github:madman-bob/idris2-xml"; flake = false; };
    indexed = { url = "github:mattpolzin/idris-indexed"; flake = false; };
    hashable = { url = "github:z-snails/idris2-hashable"; flake = false; };
    snocvect = { url = "github:mattpolzin/idris-snocvect"; flake = false; };

  };

  outputs = { self, nixpkgs, idris2, flake-utils, ... }@srcs:
    let
      inherit (builtins) removeAttrs mapAttrs;
      inherit (nixpkgs.lib) recursiveUpdate makeOverridable;
      templates = import ./templates;
      lib = import ./lib;
    in
    {
      overlay = final: prev:
        let
          compiler = (final.callPackage ./compiler.nix { idris2-src = idris2; }).c;

          idris2-pkgs = makeOverridable (import ./packageSet.nix) {
            sources = removeAttrs srcs [ "self" "nixpkgs" "flake-utils" ];
            lib = recursiveUpdate nixpkgs.lib lib;
            pkgs = final;
            idris2 = compiler;
          };
        in
        {
          inherit idris2-pkgs;
          idris2 = idris2-pkgs.idris2;
          lib = recursiveUpdate prev.lib (import ./lib);
        };

      inherit templates lib;
      defaultTemplate = templates.simple;
    } //

    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "i686-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
          ipkgs = removeAttrs pkgs.idris2-pkgs [ "override" "overrideDerivation" ];
        in
        {
          packages = ipkgs;

          defaultPackage = ipkgs.idris2;

          devShell = pkgs.mkShell {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          };

        }
      );

}

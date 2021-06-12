{ utils }:
let
  inherit (utils.builders packages) withPackages buildTOMLSource callTOML callNix extendWithLibs;

  packages = rec {

    idris2api = callNix ./idris2api.nix { };

    readline-sample = callTOML ./readline-sample.toml;

    comonad = callTOML ./comonad.toml;

    elab-util = callTOML ./elab-util.toml;

    sop = callTOML ./sop.toml;

    pretty-show = callTOML ./pretty-show.toml;

    hedgehog = callTOML ./hedgehog.toml;

    idrall = callTOML ./idrall.toml;

    lsp = extendWithLibs (callTOML ./lsp.toml);
  };

in
{
  inherit withPackages packages buildTOMLSource callNix;
}

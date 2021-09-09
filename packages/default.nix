{ utils }:
let
  inherit (utils.builders packages) extendWithPackages buildTOMLSource callTOML callNix;

  packages = rec {

    idris2api = callNix ./idris2api.nix { };

    readline-sample = callTOML ./readline-sample.toml;

    comonad = callTOML ./comonad.toml;

    elab-util = callTOML ./elab-util.toml;

    sop = callTOML ./sop.toml;

    pretty-show = callTOML ./pretty-show.toml;

    hedgehog = callTOML ./hedgehog.toml;

    experimental = callTOML ./experimental.toml;

    dom = callTOML ./dom.toml;

    idrall = callTOML ./idrall.toml;

    lsp = extendWithPackages (callTOML ./lsp.toml);
  };

in
{
  inherit extendWithPackages packages buildTOMLSource callNix;
  buildIdris = utils.buildIdris;
}

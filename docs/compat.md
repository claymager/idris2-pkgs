# Compatibility

At the moment, only a basic compatibility is provided. Attributes are parameterized by SYSTEM; most commonly, this is "x86_64-linux".

- To build Idris2 with no extra libraries:
    `nix-build`

- To run tests:
    `nix-build -A checks.SYSTEM`

- To build an executable:
    `nix-build -A packages.SYSTEM.lsp`

- To build an executable, with access to libraries:
    `nix-build -A packages.SYSTEM.lsp.withPkgs.comonad`

You should be able to replace `nix-build` in the above commands with:
    `nix-env -f . -i` to install a package
    `nix-shell` to enter a shell with a package in scope.

The standard `(idris2.withPackages (ps: with ps; [ comonad ]))` does exist, but is not easily accessible from the command prompt, so we use `idris2.withPkgs.comonad` instead.

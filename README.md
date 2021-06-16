[![](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-ubuntu.yml/badge.svg)](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-ubuntu.yml)
[![](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-macos.yml)

# Idris2-pkgs

An unofficial Idris2 package repository for Nix.

> Note: I try to be precise, but end up using Idris and Idris2 interchangeably. If I ever actually need to refer to the original, Haskell-based project, I will call it Idris1.

For a list of available Idris2 packages, see [packages/default.nix](packages/default.nix)

Compilers live in `idris2/`. Unless you want to write nix, you probably don't need to go in `utils/`.

### Supported Platforms

No matter what you want to do with this repository, to run the code, you'll need [nix]( https://nixos.org/download.html). Most of the functionality requires the experimental feature [flakes](https://nixos.wiki/wiki/Flakes) to be enabled, but `idris2-pkgs` does maintain a compatibility layer for "legacy mode," documented [here](./docs/compat.md).

The CI builds with both Linux and MacOS. Unfortunately, there is no native Windows support, but nix can be installed on Windows with [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-2---check-requirements-for-running-wsl-2).

## Quick Start

To run idris2 with some of these libraries, try the following command:

```bash
nix shell github:claymager/idris2-pkgs#idris2.withPkgs.comonad.idrall
```

That drops you into a shell with idris2 and the packages `comonad` and `idrall` installed. You can now run `idris2 -p comonad -p idrall` to enter a REPL, and import whatever you need.

Other executables that need runtime access to libraries, such as the LSP, also have access to that `withPkgs` attribute.

For other uses, check the [documentation](./docs/getting-started.md).

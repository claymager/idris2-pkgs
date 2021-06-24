[![](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-ubuntu.yml/badge.svg)](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-ubuntu.yml)
[![](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-macos.yml/badge.svg)](https://github.com/claymager/idris2-pkgs/actions/workflows/ci-macos.yml)

# Idris2-pkgs

An unofficial Idris2 package repository for Nix.

> Note: I try to be precise, but end up using Idris and Idris2 interchangeably. If I ever actually need to refer to the original, Haskell-based project, I will call it Idris1.

For a list of available Idris2 packages, see [packages/default.nix](packages/default.nix)

Compilers live in `idris2/`. Unless you want to write nix, you probably don't need to go in `utils/`.

## Supported Platforms

No matter what you want to do with this repository, to run the code, you'll need [nix]( https://nixos.org/download.html), with its "experimental feature" [flakes](https://nixos.wiki/wiki/Flakes) enabled.

The CI builds with both Linux and MacOS. Unfortunately, there is no native Windows support, but nix can be installed with [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-2---check-requirements-for-running-wsl-2).

### Run a pure Idris2 project, using packages from this repository

If those packages are already in this repository, we're in luck. You need a very simple flake, and most of it is written for you.

If you run `nix flake init -t github:claymager/idris2-pkgs#simple` in a clean directory, a simple project wile be created with a file like this one:

```nix
# flake.nix
{
  description = "My Idris 2 package";

  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.idris2-pkgs.url = github:claymager/idris2-pkgs;

  outputs = { self, nixpkgs, idris2-pkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };

        # Idris2, and the libraries you want available
        idris2-with-pkgs = pkgs.idris2.withPackages
          (ps: with ps; [
            idris2api
          ]);
      in
      rec {

        devShell = pkgs.mkShell {
          buildInputs = [ idris2-with-pkgs ];
        };

      }
    );
}
```

That looks a bit hairy, but the important part for us is here:

```
(ps: with ps; [
  idris2api
]);
```

This says "include the idris2api package when installing Idris." You can add any Idris packages you want in this (whitespace-separated) list. Now, you can run `nix develop`, and Nix will build the environment for you.

> Note: While `idris2` *can* find the packages, it doesn't know to look for them unless you tell it to. Without a proper `your-pkg.ipkg`, you'll still need to run `idris2` with `-p contrib -p elab-util -p sop -p pretty-show -p hedgehog` in order to `import Hedgehog`.

### Add a pure Idris2 library to this repository

At the moment, this is only documented for packages hosted on GitHub.

After forking this repo, there are two primary steps. We need to:
 - Create a package file `packages/MYPKG.toml`
 - Register that file in `packages/default.nix`

#### Creating the package file

Provided they exist on GitHub, most packages can be specified in [TOML](https://toml.io/en/). Documentation on the schema is [here](./doc/callToml.md).

As an example, let's look the testing library [`hedgehog`](https://github.com/stefan-hoeck/idris2-hedgehog).


```toml
#packages/hedgehog.toml
name = "hedgehog"
version = "0.0.4"

[ source ]
owner = "stefan-hoeck"
repo = "idris2-hedgehog"
rev = "929b27c4a58111b4d1327abb18a2eee4ad304f48"
# sha256 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

[ depends ]
idrisLibs = [ "elab-util", "sop", "pretty-show" ]
```

`rev` is the specific git commit to build against. `sha256` is the hash of an internal Nix file, and the typical way to get it is to try to build without one.
Nix flakes only use files tracked by git, so stage any new files and build the new package:

```
$ git add packages/hedgehog.toml
$ nix build .#hedgehog
error: hash mismatch in fixed-output derivation '/nix/store/8vhk935pzml87jj620kqhc0avkj474x2-source.drv':
 specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
 got:    sha256-Ev9LldllXHciUNHU8CcXrciW1WdxN8iW3J0kJwjsqjI=
error: 1 dependencies of derivation '/nix/store/42ypyrqdwwirzpnz2vcw0c9d6c0jyzvk-hedgehog.drv' failed to build
```

Just copy the correct sha256 and paste it into our `package/hedgehog.toml`.

```patch
# package/hedgehog.toml
  rev = "63e614776db3accebbcf4b64ac7a76e66e233e64"
- # sha256 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
+ sha256 = "Ev9LldllXHciUNHU8CcXrciW1WdxN8iW3J0kJwjsqjI="

```
And we're done! Stage and commit your changes and make a PR.

### Update a package

Assuming no dependencies have changed, a version bump in a TOML file is very easy.
 - Update the version number
 - Update `rev` to point to the target commit
 - Remove the old `sha256`
 - Run a build command
 - Get the correct `sha256`


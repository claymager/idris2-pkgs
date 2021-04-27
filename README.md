# Idris2-pkgs

An Idris2 package repository in Nix.

> Note: I try to be precise, but end up using Idris and Idris2 interchangeably. If I ever actually need to refer to the original, Haskell-based project, I will call it Idris1.

See `templates/simple` for an example, until I have time for proper documentation.

`nix flake init -t github:claymager/idris2-pkgs#simple`

## How do I...?

No matter what you want to do with this repository, to run the code, you'll need [nix]( https://nixos.org/download.html), with its "experimental feature" [flakes](https://nixos.wiki/wiki/Flakes) enabled.

### Experiment with someone else's packages

This is precisely what a `nix shell` is for!

Our specific implementation is still coming, though.

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

> Note: While `idris2` *can* find the packages, as of version 0.3.0, it doesn't know to look for them unless you tell it to. Without a proper `your-pkg.ipkg`, you'll still need to run `idris2` with `-p contrib -p elab-util -p sop -p pretty-show -p hedgehog` in order to `import Hedgehog`.

### Add a pure Idris2 library to this repository

At the moment, this is only documented for packages hosted on GitHub.

After forking this repo, there are two primary steps. We need to:
 - Create a package file `packages/MYPKG.nix`
 - Register that file in `packages/default.nix`

#### Creating the package file

As an example, let's build [`idris2-lsp`](https://github.com/idris-community/idris2-lsp).

Copy `packages/TEMPLATE.nix` and open it:

```nix
# packages/lsp.nix
{ buildIdris
, fetchFromGitHub
  # Idris dependencies
  #, elab-util

  # Foreign dependencies
  #, clang
, lib
}:

buildIdris {

  # package name
  name = "MYPACKAGE";
  # version = "0.0";

  # Commands to run before building
  # preBuild = ''
  # '';

  # idrisLibraries = [ elab-util ];

  # Foreign dependencies
  # extraBuildInputs = [ clang ];

  src = fetchFromGitHub {
    owner = "idris-lang";
    repo = "Idris2";
    rev = "";
    sha256 = lib.fakeHash;
  };

}
```

We need to tell Nix what to call this package, and where to find it:

```patch
# package/lsp.nix
  # package name
+ name = "lsp";
```

```patch
  src = fetchFromGitHub {
-   owner = "idris-lang";
-   repo = "Idris2";
-   rev = "";
+   owner = "idris2-community";
+   repo = "idris2-lsp";
+   rev = "63e614776db3accebbcf4b64ac7a76e66e233e64";
    sha256 = lib.fakeHash;
  };
```

`rev` is the specific git commit to build against. We can ignore `sha256` for now.

Looking at `lsp.ipkg`, this depends on the `idris2` api, `prelude`, and `contrib`. Two of those are included in the `idris2` executable, but we need to explicitly depend upon the `idris2` package.

```patch
   # Idris dependencies
-  #, elab-util
+  , idris2api
```

```patch
-  # idrisLibraries = [ elab-util ];
+  idrisLibraries = [ idris2api ];
```

We can now add this to the registry in `packages/default.nix`, with this line:

```patch
# packages/default.nix

+   lsp = callPackage ./lsp.nix { inherit idris2api; };
+
}
```

Nix flakes only use files tracked by git, so run

```
$ git add packages/lsp.nix
```

There's no need to commit yet. If we try to build the package, nix will complain:

```
$ nix build .#idris2.packages.lsp
error: hash mismatch in fixed-output derivation '/nix/store/8vhk935pzml87jj620kqhc0avkj474x2-source.drv':
 specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
 got:    sha256-aJV+1u3Guin5ZXj9/XoKRcWeBqdII52sY1H+RrN4X60=
error: 1 dependencies of derivation '/nix/store/42ypyrqdwwirzpnz2vcw0c9d6c0jyzvk-lsp.drv' failed to build
```

But nix is kind enough to provide us the correct checksum! So try to build it anyway. Just copy the correct sha256 and paste it into our `package/lsp.nix`.

```patch
# package/lsp.nix
    rev = "63e614776db3accebbcf4b64ac7a76e66e233e64";
-   sha256 = lib.fakeHash;
+   sha256 = "aJV+1u3Guin5ZXj9/XoKRcWeBqdII52sY1H+RrN4X60=";
  };
```

> Note: Yes, that is actually the typical way to work with hashes in Nix. That is the sha256 of a "derivation", an intermediate file built by Nix, not the repository itself.

And we're done! Stage and commit your changes, and you're ready for a PR.
`[ lsp ] Init`

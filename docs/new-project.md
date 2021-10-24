# Starting a new idris2 project

`idris2-pkgs` provides a template that makes getting started very simple. In a clean directory, run the following commands:

```sh
# Set up the project
$ nix flake new -t github:claymager/idris2-pkgs#simple mypkg
$ cd mypkg

# Build the package, and run it
$ nix shell --command runMyPkg
"Hello world!"
```

This creates a basic template with
 - `src/`, the idris2 source code
 - `mypkg.ipkg`, an [idris2 package file](https://idris2.readthedocs.io/en/latest/reference/packages.html)
 - `flake.nix`, nix logic
 - `default.nix` : nix compatibility layer, for users without flakes enabled

But we want to do more than just *run* our project. Let's run another command.

```sh
nix develop
```

This drops us into a new "development shell", a bit like a virtualenv from python. In this shell,
we now have three new executables in our path:
 * `idris2`: the compiler
 * `idris2-lsp`: a lsp server
 * `docs-serve`: [a small webserver](docs-serve.md).

Each of these knows all of the libraries our new project depends on. Which, after checking `mypkg.ipkg`, is practically nothing: just the default *prelude* and *base*.

## Adding dependencies
Let's say we want to play around with some [comonads](https://github.com/stefan-hoeck/idris2-comonad).
Ignoring nix for the moment, we obviously need to tell idris2 about it, so let's edit `mypkg.ipkg`.

```ipkg
package mypkg

main = Main
executable = runMyPkg
depends = comonad
srcdir = "src"
```

And we're done!

Well, no, not really. That is enough to tell Nix about it - we can add `import Control.Comonad` to
`src/Main.idr`, and `nix build` will work, but none of the `idris2`, `idris2-lsp`, or `docs-serve`
we brought into our path know where to find the comonad package. There's a simple solution to that,
though:

```sh
exit
nix develop
```

Restart any lsp and docs-serve instances you have running, and *now* we're done.

"But wait," you say, "that's cheating! You chose `comonad` because it's already in `idris2-pkgs`!"

Why yes, you're right. Sometimes we want to depend on something that's not included in the repository.
Let's try another one, that's already -- and only -- installed on your system.

```
-- mypkg.ipkg
depends = comonad, otherpackage
```

Most of what we've discussed so far will still work. Even `idris2 --build mypkg.ipkg` from the
development shell. With that small change, only one thing stands out from the ordinary:
`otherpackage` doesn't show up in `docs-serve`, because `docs-serve` has no idea where to look for
it. Try to run `nix build`, and we'll see the idris2 compiler within Nix encountering a similar
problem.

```
> no configure script, doing nothing
> building
> Uncaught error: Can't find package otherpackage (any)
For full logs, run 'nix log /nix/store/frmbrg220h6rqv3ijr0ds89g3b003av9-mypkg-0.0.drv'.
```

There is a way to fix this, but to do so, we'll need to dive into `flake.nix`.

## How it works

A full introduction to flakes and the Nix language is beyond the scope of this article. For now,
let's just focus on this line in `flake.nix`:

```
    mypkg = idrisPackage ./. { };
```

That's calling the function [idrisPackage](idrisPackage.md) on the current directory, with an empty attrset
(think JSON object) of configuration. It then assigns the result to the variable `mypkg`.


------------

The above description is often enough for basic idris2 executables, but packages like [alternative backends](https://idris2.readthedocs.io/en/latest/backends/custom.html) or the [lsp](https://github.com/idris-community/idris2-lsp) need something else: runtime access to libraries.

The `idris2` derivation provided by `idris2-pkgs` contains a couple of utility functions, so let's have a look in our project's `flake.nix`:

```nix
# flake.nix::9-16
let
  pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
  mypkg = pkgs.idris2.buildTOMLSource ./. ./mypkg.toml;
in
{
  defaultPackage = mypkg;
}
```
`buildTOMLSource` is the function that constructs our package out of the source directory and `./mypkg.toml`. What we want, is to be able to build `mypkg.withPkgs.comonad.hedgehog`, or the like, as we can do with the `idris2` derivation.

This functionality is provided by wrapping our package with a call to `extendWithPackages`.

```nix
# flake.nix::9-16
let
  pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
  i = pkgs.idris2;
  mypkg = i.extendWithPackages (i.buildTOMLSource ./. ./mypkg.toml);
in
{
  defaultPackage = mypkg;
}
```

To use this function, we'll also need to tell `idris2-pkgs` the name of the executable to extend. This is done in `mypkg.toml`:

### Building a `devShell`

By default, executing `$ nix develop` drops you into a shell environment with all of the dependencies necessary to build the `defaultPackage`. We can override this value, perhaps bringing in tools for profiling, linting, or the LSP server, but doing so means we need to be fairly explicit about the included libraries again.

I tend to use something like this:
```nix
# flake.nix::9-25
let
  pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
  mypkg = pkgs.idris2.buildTOMLSource ./. ./mypkg.toml;
in
{ 
  defaultPackage = mypkg;

  devShell =
    let withDeps = base: base.withPackages (p: mypkg.idrisLibraries ++ mypkg.idrisTestLibraries);
    in
    pkgs.mkShell {
      buildInputs = map withDeps [
        pkgs.idris2
        pkgs.idris2.packages.lsp
      ];
    };
}
```
Note that any environment variables, `nixpkgs` dependencies, or testing libraries will need to be re-added to the `devShell` derivation.

### Publishing to `idris2-pkgs`

The `buildTOMLSource` function we've been using ignores the `[ source ]` attributes of the TOML files, so we can use the same specification to publish the package. See [here](./new-package.md) for documentation on publishing to `idris2-pkgs`.

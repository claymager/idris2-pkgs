# Starting a new idris2 project

`idris2-pkgs` provides a template that makes getting started very simple. In a clean directory, run the following commands:

```bash
# Set up the project
$ nix flake new -t github:claymager/idris2-pkgs#toml mypkg
$ cd mypkg
# Build the package, and run it
$ nix shell --command runMyPkg
"Hello world!"
```

This creates a basic template with
 - `src/`, the idris2 source code
 - `mypkg.ipkg`, an [idris2 package file](https://idris2.readthedocs.io/en/latest/reference/packages.html)
 - `mypkg.toml`, a simplified [build configuration file](./callToml.md), 
 - `flake.nix`, nix logic
 - `default.nix` : nix compatibility layer, for users without flakes enabled

If you want to change the name of `mypkgs.ipkg`, be sure to update the `name` attribute of `mypkg.toml`. Likewise, to change `mypkg.toml`, update the reference in `flake.nix`.

### Adding dependencies
Let's say we want to `import Control.Comonad` from [comonad](https://github.com/stefan-hoeck/idris2-comonad). We need to include the dependency twice: once in `mypkg.toml` to tell Nix to build the library, and once in `mypkg.ipkg` to have Idris2 look for the library at build time.

```toml
# mypkg.toml
name = "mypkg"
version = "0.0"

[ source ]
host = "local"

[ depends ]
idrisLibs = [ "comonad" ]
```

```ipkg
-- mypkg.ipkg
package mypkg

main = Main
executable = runMyPkg
depends = comonad
srcdir = "src"
```


Let's say we also want the testing library [hedgehog](https://github.com/stefan-hoeck/idris2-hedgehog), which further depends on other idris2 libraries. If we add that to the `toml` specification, `idris2-pkgs` includes all of those extra dependencies for us.

```toml
# mypkg.toml::4-5
[ depends ]
idrisLibs = [ "comonad", "hedgehog" ]
```

But we have to be more explicit in the `ipkg` file, or when calling `idris2` in the shell.

```ipkg
-- mypkg.ipkg::5-10
depends = comonad,
          contrib,
          elab-util,
          sop,
          pretty-show,
          hedgehog
```

The TOML interface includes support for a number of other dependency types, and is documented [here](./callToml.md).

### Making a new backend

The above description is often enough for basic idris2 executables, but packages like [alternative backends](https://idris2.readthedocs.io/en/latest/backends/custom.html) or the [lsp](https://github.com/idris-community/idris2-lsp) need something else: runtime access to libraries.

The `idris2` derivation provided by `idris2-pkgs` contains a couple of utility functions, so let's have a look in our project's `flake.nix`:

```nix
# flake.nix::9-16
let
  pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
  mypkg = pkgs.idris2.callTOML ./mypkg.toml;
in
{
  defaultPackage = mypkg;
}
```
`callTOML` is the function that constructs our package out of the source directory and `./mypkg.toml`. What we want, is to be able to build `mypkg.withPkgs.comonad.hedgehog`, or the like, as we can do with the `idris2` derivation.

This functionality is provided by wrapping our package with a call to `extendWithPackages`.

```nix
# flake.nix::9-16
let
  pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
  i = pkgs.idris2;
  mypkg = i.extendWithPackages (i.callTOML ./mypkg.toml);
in
{
  defaultPackage = mypkg;
}
```

To use this function, we'll also need to tell `idris2-pkgs` the name of the executable to extend. This is done in `mypkg.toml`:

```
# mypkg.toml
name = "mypkg"
executable = "runMyPkg"
version = "0.0"

[ source ]
host = "local"

[ depends ]
idrisLibs = [ "comonad", "hedgehog" ]
```

### Building a `devShell`

By default, executing `$ nix develop` drops you into a shell environment with all of the dependencies necessary to build the `defaultPackage`. We can override this value, perhaps bringing in tools for profiling, linting, or the LSP server, but doing so means we need to be fairly explicit about the included libraries again.

I tend to use something like this:
```nix
# flake.nix::9-25
let
  pkgs = import nixpkgs { inherit system; overlays = [ idris2-pkgs.overlay ]; };
  mypkg = pkgs.idris2.callTOML ./mypkg.toml;
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

The `callTOML` function we've been using is the same that we use internally, in `packages/default.nix`. All we'll need to do is update the `[ source ]` attributes of the TOML file to point to a publically available github repo, and we can use the same specification to publish the package. See [here](./new-package.md) for documentation on publishing to `idris2-pkgs`.

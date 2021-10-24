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
 - `default.nix` : nix compatibility layer, for users without flakes enabled
 - `flake.nix`, nix logic
 - `mypkg.ipkg`, an [idris2 package file](https://idris2.readthedocs.io/en/latest/reference/packages.html)
 - `src/`, the idris2 source code
 - `test/`, which we'll ignore for now.

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

There is a way to fix this, but to do so, we'll need to peek into `flake.nix`.

## Other idris2 dependencies

A full introduction to flakes and the Nix language is beyond the scope of this article. For now,
let's just focus on these lines in `flake.nix`:

```
    mypkg = idrisPackage ./. { };
    runTests = idrisPackage ./test { extraPkgs.mypkg = mypkg; };
```

That's calling the function [idrisPackage](idrisPackage.md) on the current directory, with an empty attrset
(think JSON object) of configuration. It then assigns the result to the variable `mypkg`.

Then comes the interesting bit. We're taking that output, and using the configuration option `extraPkgs`,
passing it to *another* package called `runTests`.

So what happens if we try doing that same thing?

```
    otherpackage = idrisPackage /home/user/otherpackage { };
    mypkg = idrisPackage ./. { extraPkgs.otherpackage = otherpackage; };
    runTests = idrisPackage ./test {
        extraPkgs.mypkg = mypkg;
        extraPkgs.otherpackage = otherpackage;
    };
```

Try `nix build` again. If `idrisPackage` can figure out how to build that other package, then
`mypkg` should build successfully. We can add `otherpackage` to `test/runTests.ipkg`, run `nix run
.#runTests`, and see that even with two dependencies that are not in `idris2-pkgs`, "tests passed".

There are some potential pitfalls here, though.
  - Nix can be rather funny with paths. Make sure that all relative paths are contained within the
    flake.
  - If a flake is a git repository, all imported files must be tracked by git.
  - The "otherpackage" key in `extraPkgs.otherpackage` must match the name used by idris (`depends =
    otherpackage`) *precisely* to be correctly found. If the package name contains unicode, wrap the
    nix key in quotes, as in `extraPkgs."otherpackage"`.
  - There are the standard idris2 dependency rules, which we handled above. If `runTests` depends on
    a module from `mypkg` which itself depends on `otherpackage`, we need to explicitly pass it to
    idris2 in `runTests.ipkg` and to Nix in runTests's `extraPkgs`.

## Runtime libraries

The above description is often enough for basic idris2 executables and libraries, but the
executables in [alternative
backends](https://idris2.readthedocs.io/en/latest/backends/custom.html) or the
[lsp](https://github.com/idris-community/idris2-lsp) need something else: runtime access to
libraries. Otherwise, the program will build just fine, but when it comes time to run, we'll get
an error like the following:

`CRITICAL UNCAUGHT ERROR Can't find package prelude (any)`

Fortunately, `idris2-pkgs` provides a function that handles this: `useRuntimeLibs`. As
an example, let's add runtime idris2 support to `mypkg`. Completely ignoring the actual idris
side of things, of course.

Back in our `flake.nix`, let's look at this line:

```
   inherit (pkgs.idris2-pkgs._builders) idrisPackage devEnv;
```


That's bringing the builder functions `idrisPackage`, which we've seen, and `devEnv`, the brains
behind our `nix develop`, into scope.

>  Note: `inherit (attrset) x y;` is just sugar for `x = attrset.x; y = attrset.y;`. You'll
>  see this often if you dig into `idris2-pkgs`.

Let's add bring it into scope, and use it on the `mypkg` executable:
```
   inherit (pkgs.idris2-pkgs._builders) idrisPackage devEnv useRuntimeLibs;
   otherpackage = idrisPackage /home/user/otherpackage { };
   mypkg = useRuntimeLibs (idrisPackage ./. { extraPkgs.otherpackage = otherpackage; });
```

## Alternate build commands and non-idris dependencies

There is a lot of power available in the `args`. For the Nix-savvy, `idrisPackage` forwards its `args` to `buildIdris`, which then passes them on
to `stdenv.mkDerivation`.

## Further Reading

- [idrisPackage](idrisPackage.md)
- [Publishing to `idris2-pkgs`](new-package.md)


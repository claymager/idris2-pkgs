# Versioning in a flake

To automatically update inputs to a flake, run one of the following:

```
nix flake update
nix build <whatever> --recreate-lock-file
nix build <whatever> --update-input <only-this-input>
```

In `idris2-pkgs`, be sure to run `nix-build --no-out-links -A checks.SYSTEM` (where system is one of "x86_64-linux", "x86_64-darwin", or "i686-linux") afterwards, to be sure that everything is compatible.

If you would prefer to pick the git revision by hand, that is possible by specifying it in the input url. At the time of writing, we use:

```nix
{
    inputs.idris2-src = { url = "github:idris-lang/idris2/0a29d06f"; flake = false; };
}
```

because (at least) the idris2 lsp does not compile with `idris2/main`.

## Overriding an input

If we would prefer to use a newer (or older) version of a particular package, and the target package is a flake, we can override any of the inputs to `idris2-pkgs`.

Where we currently have in the `flake.nix` inputs:
```
{
  inputs.idris2-pkgs = { url = github:claymager/idris2-pkgs"; };
}
```

we'll need to add another input, and tell idris2-pkgs to follow that one.

```
{
  inputs.idris2-main = { url = "github:idris-lang/idris2"; flake = false; };
  inputs.idris2-pkgs = {
     url = "github:claymager/idris2-pkgs";
     inputs.idris2-src.follows = "idris2-main";
  };
}
```

We may need to update our `outputs` (remember, it is a function on all inputs, and we've juts added an input).

Our next nix command will automatically take care of downloading the new idris2 source, recompiling idris2, and rebuilding anything necessary.

Again note that, as of the time of writing, the LSP does not work with `main`, so `nix develop` -- which includes the LSP -- will fail to build.

## Further reading

- [flakes](https://nixos.wiki/wiki/Flakes)

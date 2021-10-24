# idrisPackage

`idrisPackage` is the primary method of building an idris package in this repository.

function in two arguments (a path `src`, and an attrset of configuration values `args`), and returns an
[idris2 package](idris2_package.md).

```nix
{
  mypkg = idrisPackage ./. { };
}
```

[Source](../utils/buildRepo.nix)

The general idea is that it takes a source directory, makes a guess at the `ipkg` file, and uses
that file to fill out some configuration details. It then passes everything to `buildIdris`.

## Config options

The attrset `args` may contain the following attrs:

- `ipkgFile`: String
  idrisPackage makes a guess, but it is often necessary to explicitly state which ipkg file to use.
  This should be a string containing a relative path to a file in the source directory.

- `extraPkgs`: Attrset Ipkg
  When the target depends on some idris package that *isn't* in idris2-pkgs, this allows that
  dependency to be correctly passed to `buildIdris`. It may also be necessary for disambiguation
  if two packages share a name.

All arguments to `buildIdris` or `stdenv.mkDerivation` are also accepted.

## Location

`idrisPackage`, and the other user-facing functions, are found in `idris2-pkgs._builders`.

They are not currently a flake output, and are only accessible via the overlay.

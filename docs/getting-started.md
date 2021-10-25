# Getting Started

## Tutorials

- [Starting a new project](./new-project.md)
- [Adding to the repository](./new-package.md)
- [Versioning](versioning.md)

## Other documentation

- [Builders](builders.md)
- [docs-serve](docs-serve.md)
- [The Build Process](build-process.md)
- [Without flakes](./compat.md)

## Glossary

- **attrs**:
  Keys of an attrset

- **attrset**:
  A nix expression of key-value pairs roughly corresponding to a JSON Object or a
  Python dictionary.

- **derivation**: Build instructions for some output

  Informally, a derivation is an `attrset` with the special property that it can be coerced to a
  path into the nix store (a.k.a. the **realisation** of that derivation).

- **realisation**:
  Build output of a derivation

  A realisation is is the result of running `nix build` on some derivation; this is a path into
  the Nix store, and the contents at that path.

- **package**: Derivation of an Idris2 project

  A package is the output of [buildIdris](buildIdris.md) or it's wrapper [idrisPackage](idrisPackage.md).

  The realisation of a package is typically the executable produced by `idris2 --build`, plus
  whatever it needs to run. In addition to the standard derivation attrs, it contains `asLib`,
  `withSource`, and `docs`; each of which are derivations of their own.

- **library**: Derivation of `<package>.asLib`, or its realisation

  When idris2 package `p` wants to import modules from another package `q`, it depends on
  the library of `q`. The library typically contains only the `ttc` files of the dependency.

- **source**:
  - As a package component:

    The derivation of `<package>.withSource`, or its realisation.
    Built with `idris2 --install-with-src`.

  - As input for package `p`: `src` attribute of `stdenv.mkDerivation`

    Roughly, a nix derivation copy of whichever path it points to. All relative paths in `p`'s
    derivation are relative to this.

- **docs**:
  - As a package component:
    The derivation of `<package>.docs`, or its realisation. The HTML description of a library
    built by `idris2 --mkdoc`.

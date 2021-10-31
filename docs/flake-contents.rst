idris2-pkgs
===========

The primary way of interfacing with idris2-pkgs is with its overlay.

An example of the per-project configuration is shown in the `default template_`.

If you're using NixOS (or home-manager), put this in your ``configuration.nix`` (or ``home.nix``),
to install the idris2-lsp.

.. code-block::nix

    let idris2-pkgs = import (builtins.fetchTarball { url =
    "https://github.com/claymager/idris2-pkgs/tarball/main"; }); in { nixpkgs.overlays = [
    idris2-pkgs.overlay ]; home.packages = [ pkgs.idris2-pkgs.lsp ]; }

.. note::

    That only installs the LSP server and the Prelude and Base libraries it needs to function. If
    you'd like more, explore the `Idris2 interpreters`_ section below.

Within that ``pkgs.idris2-pkgs`` is the special attribute `_builders`_ and every package produced
by this repository.

.. _`_builders`: builders.rst

Package Structure
-----------------

When we build a package, such as by ``nix build .#<package>``, we're essentially calling
``idris2 --build`` for that package and collecting the executable (if any) it produces.

Each idris2 package also includes three other derivations:

- ``<package>.asLib``, the library that would get installed with ``idris2 --install``

- ``<package>.withSource``, the reference library installed with
  ``idris2 --install-with-src``

- ``<package>.docs``, the documentation produced by ``idris2 --mkdoc``

Note that while those derivations do *build* the libraries, they do nothing to *install* them. Idris
compilers won't be able to find a library that was included into an environment with
``<package>.asLib``. For that, we need to explore the interpreters themselves.

Idris2 Interpreters
-------------------

These packages include any executable that needs to interpret Idris2 code at runtime, such as the
LSP server or the Idris2 compiler itself. They automatically have access to the *Prelude* and *Base*
libraries and the support files distributed with the compiler.

To get instances with other libraries, a few utilities are included.

- ``<package>.withLibraries`` and ``<package>.withSources``.

  These function similar to ``python.withPackages``, and take a function like ``(ps: [ ps.comonad ps.idrall ])`` to build a
  <package> that can import from comonad_ and idrall_.

- ``<package>.withLibs`` and ``<package>.withSrcs``, two infinite trees of derivations.

  To use these, we call ``nix build .#<package>.withLibs.comonad.idrall``.

.. _comonad: https://github.com/stefan-hoeck/idris2-comonad

.. _idrall: https://github.com/stefan-hoeck/idris2-comonad

Getting Started
===============

Tutorials
---------

-  `Starting a new project <./new-project.rst>`__
-  `Adding to the repository <./new-package.rst>`__
-  `Versioning <versioning.rst>`__

Other documentation
-------------------

-  `idris2-pkgs contents <flake-contents.rst>`__
-  `Builders <builders.rst>`__
-  `docs-serve <docs-serve.rst>`__
-  `The Build Process <build-process.rst>`__
-  `Without flakes <./compat.rst>`__

Glossary
--------

attrs:
   names of an attrset

attrset:
   A nix expression of name-value pairs roughly
   corresponding to a JSON Object or a Python dictionary.

derivation:
   Build instructions for some output

   Informally, a derivation is an attrset with the special property
   that it can be coerced to a path into the nix store (a.k.a. the
   *realisation* of that derivation).

realisation:
   Build output of a derivation

   A realisation is is the result of running ``nix build`` on some
   derivation; this is a path into the Nix store, and the contents at
   that path.

package:
   Derivation of an Idris2 project. A package is made from the function
   ``buildIdris`` or its wrapper ``idrisPackage``.

   The realisation of a package is typically the executable produced by
   ``idris2 --build``, plus whatever it needs to run. In addition to the
   standard derivation attrs, it contains ``asLib``, ``withSource``, and
   ``docs``; each of which are derivations of their own.

library:
   ``<package>.asLib``

   When idris2 package ``p`` wants to import modules from another
   package ``q``, it depends on the library of ``q``. The library
   typically contains only the ``ttc`` files of the dependency.

source:
   ``<package>.withSource``

   Built with ``idris2 --install-with-src``.

docs:
   ``<package>.docs``

   The HTML description of a library built by ``idris2 --mkdoc``.

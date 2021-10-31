Builders
========

These are the user-facing nix functions for working with idris2
packages.

The builders are not currently a flake output, and are only accessible
via the overlay, in ``pkgs.idris2-pkgs._builders``.

idrisPackage : Src -> Cfg -> Package
------------------------------------

``idrisPackage`` is the primary method of building an idris package in
this repository.

function in two arguments (a path ``src``, and an attrset of
configuration values ``cfg``), and returns an idris2 package.

.. code:: nix

   {
     mypkg = idrisPackage ./. { };
   }

The general idea is that it takes a source directory, makes a guess at
the ``ipkg`` file, and uses that file to fill out some configuration
details. It then passes everything to ``buildIdris``.

-  `source <../builders/idris-package.nix>`__

Config options
~~~~~~~~~~~~~~

-  ``ipkgFile``: String idrisPackage makes a guess, but it is often
   necessary to explicitly state which ipkg file to use. This should be
   a string containing a relative path to a file in the source
   directory.

-  ``extraPkgs``: Attrset Ipkg When the target depends on some idris
   package that *isn’t* in idris2-pkgs, this allows that dependency to
   be correctly passed to ``buildIdris``. It may also be necessary for
   disambiguation if two packages share a name.

All arguments to ``buildIdris`` or ``stdenv.mkDerivation`` are also
accepted and forwarded on.

buildIdris : Cfg -> Package
---------------------------

``buildIdris`` builds all idris2 packages. It first builds an
intermediate derivation with both the source and ttc output of
compilation, then passes everything onto an installation derivation with
overrides for using the package as a build library, as a reference
“source” library, and as documentation.

-  `detailed explanation <build-process.rst>`__
-  `source <../builders/buildIdris.nix>`__

Required config
~~~~~~~~~~~~~~~

-  ``name`` : String
-  ``src`` : Source derivation, like from ``pkgs.fetchFromGitHub``.

.. _config-options-1:

Config options
~~~~~~~~~~~~~~

All of the ``stdenv.mkDerivation`` options, plus:

-  ``idrisLibraries`` : List of idris2 packages

-  ``idrisTestLibraries`` : List of idris2 packages only used in
   checkPhase

-  ``codegen`` : String Which codegen to use when compiling executables.
   Default “chez”.

-  ``ipkgFile`` : String Same ``ipkgFile`` as in ``idrisPackage``, but
   it’s only used for the build/install commands. No dependency
   management here.

-  (``preBuild``, ``bostBuild``, ``preCheck``, ``postCheck``,
   ``preBinInstall``, ``postBinInstall``, ``preLibInstall``,
   ``postLibInstall``, ``preDocBuild``, ``postDocBuild``,
   ``preDocInstall``, ``postDocInstall`` : Hook) A Hook is a string with
   either bash commands or a bash function that is run at a certain
   point in the build process.

   Any other string-valued attribute is accepted and passed in to the
   build process as an environment variable.

devEnv : Package -> Package
---------------------------

``devEnv`` takes an idris2 package ``p``, gets its library dependencies,
and brings into scope:

- an idris2 compiler with all packages needed to
compile ``p``

- an idris2-lsp server with all packages and sources
needed to work on ``p``

- `docs serve <docs-serve.rst>`__

Defined in `../builders/default.nix <../builders/default.nix>`__. For
usage, see the `templates <../templates/simple/flake.nix>`__.

useRuntimeLibs : Package -> Package
-----------------------------------

``useRuntimeLibs`` is for executables like the LSP, which use the
``idris2`` library to access ``ttc`` files or support data.

This adds a few attributes to the package: - ``withLibraries``: (Attrset
Package -> List Package) -> Package Similar to
``pkgs.python3.withPackages``, but does not provide the compiled output
of each package. It only makes the base capable of importing them as a
library.

-  ``withSources``: (Attrset Package -> List Package) -> Package Like
   ``withLibraries``, but includes the source of each ``ttc`` file for
   reference.

-  ``withLibs``: infinite tree of packages ``withLibraries``, but with a
   different api.

   Instead of typing
   ``lsp.withPackages (ps: [ ps.comonad ps.hedgehog ])``, it is
   sufficient to write ``lsp.withPkgs.comonad.hedgehog``.

-  ``withSrcs``: infinite tree of packages ``withLibs``, but also
   provides the source of each ``ttc`` file.

Defined in `../builders/default.nix <../builders/default.nix>`__

compiler : Derivation
---------------------

This is the derivation for the ``idris2`` binary used to compile all of
the idris code in ``idirs2-pkgs``. Not overly interesting by itself.

``build-idris2-pkgs`` : Compiler -> Attrset Package
---------------------------------------------------

In theory, there are multiple executables capable of interpretting and
compiling idris2 code. To rebuild everything in idris2-pkgs with some
other idris2 compiler, pass ``_build-idris2-pkgs`` that compiler.

Here, ``Compiler`` is a an attrset of the form:

.. code:: nix

   {
     compiler = pkgs.idris2; # derivation capable of compiling idris2 code
     support = <support>; # derivation with support libs of default idris package
   }

buildTOMLSource, callNix, callTOML
----------------------------------

deprecated builders

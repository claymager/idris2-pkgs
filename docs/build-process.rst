The Build Process
=================

How buildIdris works
--------------------

Throughout this, we’ll reference ``cfg`` as though it’s an independent
expression. ``cfg`` is whatever was passed as the argument to
``buildIdris``. It’s an attribute set with some constraints - it must
contain “name” and “src” attributes, and any attributes *not* expected
by ``buildIdris`` or ``stdenv.mkDerivation`` must refer to strings.

``mypkg = buildIdris cfg;``

Build environment
~~~~~~~~~~~~~~~~~

Source:

In PATH: - idris2, with some libraries - any buildInputs,
nativeBuildInputs, etc are provided as cfg.

Every phase has pre- and post-hooks for executing extra bash commands,
and some minor environment-prepping commands like ``mkdir $out``.
Alternatively, every phase can be overriden entirely, by supplying
something like

::

   mypkg = buildIdris { buildPhase = "make build"; ...

Stage 1: The Build
~~~~~~~~~~~~~~~~~~

1. buildPhase: ::

   sh     idris2 --build mypkg.ipkg

2. checkPhase: (only runs if ``cfg.doCheck`` evaluates to ``true``) ::

   sh     # If there is a 'test.ipkg' near the project root, build it
   find . -maxdepth 2 -name test.ipkg -exec idris2 --build {} \;

The build then pauses to cache the results: - (not overridable)
installPhase: ``sh     cp -r * $out/``

Stage 2: Installation
~~~~~~~~~~~~~~~~~~~~~

One of the following tracks is run:

A. binInstallPhase: (assuming there’s *something* in build/exec)::

   sh     mv build/exec/* $out/bin
   # if cfg.runtimeLibs, also does some wrapping

B.  libInstallPhase: ::

    ``sh     idris2 --install mypkg.ipkg``

   -  The same phase is used for both ``asLib`` and ``withSource``, so
      it’s not overridable. The hooks ``preLibInstall`` and
      ``postLibInstall`` are available, and apply to both derivations.
   -  The actual derivations of ``asLib`` and ``withSource`` join the
      output of this with the same form of each idris2 dependency.

C.  Docs:

   1.  docBuildPhase: ``sh   idris2 --mkdoc mypkg.ipkg``

   2.  docInstallPhase: ``sh   mv build/docs/* $out/doc/mypkg-0.1.0/``

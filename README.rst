|image1| |image2|

Idris2-pkgs
===========

An unofficial Idris2 package repository for Nix.

   Note: I try to be precise, but end up using Idris and Idris2
   interchangeably. If I ever actually need to refer to the original,
   Haskell-based project, I will call it Idris1.

Unfortunately, there isn’t a precise list of installable packages in
userspace yet. You can get an idea by scanning the inputs of
`flake.nix <flake.nix>`__, or programmatically through nix by running:

.. code:: sh

   nix eval --apply builtins.attrNames github:claymager/idris2-pkgs#packages.x86_64-linux

Binary Cache
------------

This repository uses Cachix_ for caching, though that is still highly experimintal.

If you run ``cachix use cm-idris2-pkgs``, it should configure your nix
to use the cache. The cachix command is only needed for setup, so feel free
to run that in a nix shell.

- **cache name** ``cm-idris2-pkgs``

- **public key** ``cm-idris2-pkgs.cachix.org-1:YB2oJSEsD5oMJjAESxolC2GQtE6B5I6jkWhte2gtXjk=``

Supported Platforms
-------------------

No matter what you want to do with this repository, to run the code,
you’ll need `nix <https://nixos.org/download.html>`__. Most of the
functionality requires the experimental feature
`flakes <https://nixos.wiki/wiki/Flakes>`__ to be enabled, but
``idris2-pkgs`` does maintain a compatibility layer for “legacy mode,”
documented `here <./docs/compat.rst>`__.

The CI builds with both Linux and MacOS. Unfortunately, there is no
native Windows support, but nix can be installed on Windows with `WSL
2 <https://docs.microsoft.com/en-us/windows/wsl/install-win10#step-2---check-requirements-for-running-wsl-2>`__.

Quick Start
-----------

To run idris2 with some of these libraries, try the following command:

.. code:: bash

   nix shell github:claymager/idris2-pkgs#idris2.withLibs.comonad.idrall

That drops you into a shell with idris2 and the packages ``comonad`` and
``idrall`` installed. You can now run ``idris2 -p comonad -p idrall`` to
enter a REPL, and import whatever you need.

Other executables that need runtime access to libraries, such as the
LSP, also have access to that ``withPkgs`` attribute.

For other uses, check the `documentation <./docs/README.rst>`__.

License
=======

Idris2-pkgs is licensed under the `MIT License <LICENSE>`__.

Note: MIT license does not apply to the packages built by Idris2-pkgs,
merely to the files in this repository (the Nix expressions, build
scripts, etc.). It also might not apply to patches included in
idris2-pkgs, which may be derivative works of the packages to which they
apply. The aforementioned artifacts are all covered by the licenses of
the respective packages.

.. |image1| image:: https://github.com/claymager/idris2-pkgs/actions/workflows/ci-ubuntu.yml/badge.svg
   :target: https://github.com/claymager/idris2-pkgs/actions/workflows/ci-ubuntu.yml
.. |image2| image:: https://github.com/claymager/idris2-pkgs/actions/workflows/ci-macos.yml/badge.svg
   :target: https://github.com/claymager/idris2-pkgs/actions/workflows/ci-macos.yml

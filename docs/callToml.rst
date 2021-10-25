Building from TOML
==================

NOTE: the functions described herein may be deprecated soon.

Many packages can be built from a TOML specification. This flake
provides two functions: - ``callTOML`` : (toml : Path) -> IdrisPkg - For
specifying packages to include in ``idris2-pkgs`` - Currently requires
package to be hosted on GitHub - ``callTOMLSource`` : (projectRoot :
Path) -> (toml : Path) -> IdrisPkg - For using idris2-pkgs locally - If
either path points outside of the flake’s directory, you will need to
use ``--impure`` with any Nix commands

Many basic functionalities are available from the TOML interface, and
are detailed below. To use more advanced features like specifying the
commit of a dependency, you will have to call the nix function
``buildIdris`` directly. For help porting a TOML specification to a nix
one, see the `implementation <../utils/callToml.nix>`__ of callTOML.

Usage
-----

The minimum a package needs to build is here:

.. code:: toml

   #package/minimum.toml
   name = "mypkg"

   [ source ]
   owner = "my-github-username"
   repo = "my-project"
   rev = "tag-or-hash-of-commit"
   sha256 = "hash-of-intermediate-buildifile"

Without ``sha256``, nix will assume the fake hash “AAA…” and fail,
providing the correct hash. So just comment out that line, run, and
copy-paste to get the correct ``sha256``.

In addition, there are a number of optional fields that may be
specified.

-  ``version``: String

   -  default: ``"0.0"``
   -  example: `hedgehog <../packages/hedgehog.toml>`__

-  ``codegen``: String

   -  default: “chez”
   -  The default idris2 has runtime access to ``chez``. If using
      another codegen, be sure to edit ``depends.buildInputs``.

-  ``ipkgFile``: String

   -  default: “${name}.ipkg”
   -  example: `readline-sample <../packages/readline-sample.toml>`__

-  ``[ patch ]``

   -  ``preBuild``, ``postBuild``

      -  example: `readline-sample <../packages/readline-sample.toml>`__
      -  Extra commands to run when running the build command

   -  ``preBinInstall``, ``postBinInstall``

      -  Extra commands to run when installing the executable

   -  ``preLibInstall``, ``postLibInstall``

      -  Extra commands to run when installing modules

-  ``[ depends ]``

   -  ``idrisLibs`` : List String

      -  example: `hedgehog <../packages/hedgehog.toml>`__
      -  Every element is the name of a library package this one depends
         on, where “name” comes from the LHS of a declaration in
         `packages/default.nix <../packages/default.nix>`__.
      -  Unlike in an ``ipkg`` file, libraries included with Idris
         (``contrib``, ``network``, ``test``; *NOT* ``idris2api``) do
         not need to be declared here.

   -  ``buildInputs`` : List String

      -  example: `readline-sample <../packages/readline-sample.toml>`__
      -  `nixpkgs <https://search.nixos.org/packages>`__ packages
         containing dependencies needed at compile time for the target
         package.

-  ``[ test ]``

   -  ``enable``: Bool

      -  default: ``false``
      -  Whether to run the tests specified by ``test.command``

   -  ``command``: string

      -  default: ``"idris2 --build test.ipkg"``

   -  ``idrisLibs`` : List String

      -  Functions exactly like ``depends.idrisLibs``, but are only
         included if testing is enabled.

   -  ``preCheck``, ``postCheck``

      -  example: `pretty-show <../packages/pretty-show.toml>`__

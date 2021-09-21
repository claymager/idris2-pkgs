
# Building from TOML

Many packages can be built from a TOML specification. This flake provides the function `callTOML`, which we make heavy use of in `packages/`.
 - `callTOML` : (toml : Path) -> IdrisPkg
    - Currently requires the source code to be hosted locally or on GitHub

`callTOML` can be used to make packages from a local repository, but sometimes you'll want to *depend on* those local packages, without publishing them into `idris2-pkgs`.
When you need to depend on locally defined packages, you may inject them into `callTOML` by instead using `extendCallTOML`.

 - `extendCallTOML` : (extraPkgs : AttrSet IdrisPkg) -> (toml : Path) -> IdrisPkg

Many basic functionalities are available from the TOML interface, and are detailed below. To use more advanced features like specifying the commit of a dependency, you will have to call the nix function `buildIdris` directly. For help porting a TOML specification to a nix one, see the [implementation](../utils/callToml.nix) of callTOML.

## Usage

The minimum a package needs to build is here:

```toml
#package/minimum.toml
name = "mypkg"

[ source ]
# host = "github"
owner = "my-github-username"
repo = "my-project"
rev = "tag-or-hash-of-commit"
sha256 = "hash-of-intermediate-buildfile"
```

Without `sha256`, nix will assume the fake hash "AAA..." and fail, providing the correct hash.
So just set the other three fields, comment out that line, run, and copy-paste to get the correct `sha256`.

### Alternate sources

In addition to the default host "github", we can tell Nix to use the source code from elsewhere.
This is done by setting `[source].host`. Currently, the only other implemented `host` is a local repository.

```toml
[ source ]
host = "local"
path = "project/root"
```

`path` may be absolute or relative, and its default is `"."`, or the directory containing the TOML file.

There are some sharp corners to watch out for.
- When using absolute paths, nix commands may require the build flag `--impure`.
- When using relative paths, all referenced files must be within the flake. That is, they must still be within the directory containing `flake.nix`, or its children.

### Others options

In addition, there are a number of optional fields that may be specified.

* `version`: String
    - default: `"0.0"`
    - example: [hedgehog](../packages/hedgehog.toml)

- `codegen`: String
    - default: "chez"
    - The default idris2 has runtime access to `chez`. If using another codegen, be sure to edit `depends.buildInputs`.

* `ipkgFile`: String
    - default: "\${name}.ipkg"
    - example: [readline-sample](../packages/readline-sample.toml)

* `[ patch ]`
    - `preBuild`, `postBuild`
        - example: [readline-sample](../packages/readline-sample.toml)
        - Extra commands to run when running the build command
    - `preBinInstall`, `postBinInstall`
        - Extra commands to run when installing the executable
    - `preLibInstall`, `postLibInstall`
        - Extra commands to run when installing modules

* `[ depends ]`
    - `idrisLibs` : List String
        - example: [hedgehog](../packages/hedgehog.toml)
        - Every element is the name of a library package this one depends on, where "name" comes from the LHS of a declaration in [packages/default.nix](../packages/default.nix).
       - Unlike in an `ipkg` file, libraries included with Idris (`contrib`, `network`, `test`; *NOT* `idris2api`) do not need to be declared here.
    - `buildInputs` : List String
        - example: [readline-sample](../packages/readline-sample.toml)
        - [nixpkgs](https://search.nixos.org/packages) packages containing dependencies needed at compile time for the target package.

- `[ test ]`
    - `enable`: Bool
        - default: `false`
        - Whether to run the tests specified by `test.command`
    - `command`: string
        - default: `"idris2 --build test.ipkg"`
    - `idrisLibs` : List String
        - Functions exactly like `depends.idrisLibs`, but are only included if testing is enabled.
    - `preCheck`, `postCheck`
        - example: [pretty-show](../packages/pretty-show.toml)

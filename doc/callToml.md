# Building from TOML

The builder function `callTOML` builds a GitHub-hosted Idris2 package from a TOML specification. View its implementation [here](../utils/callToml.nix).

The minimum a package needs to build is here:

```toml
#package/minimum.toml
name = "mypkg"

[ source ]
owner = "my-github-username"
repo = "my-project"
rev = "hash-of-latest-commit"
sha256 = "hash-of-intermediate-buildifile"
```

Without `sha256`, nix will assume the fake hash "AAA..." and fail, providing the correct hash. So just comment out that line, run, and copy-paste to get the correct `sha256`.


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
    - `preCheck`, `postCheck`
        - example: [pretty-show](../packages/pretty-show.toml)

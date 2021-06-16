### Add a pure Idris2 library to this repository

At the moment, this is only documented for packages hosted on GitHub.

After forking this repo, there are two primary steps. We need to:
 - Create a package file `packages/MYPKG.toml`
 - Register that file in `packages/default.nix`

#### Creating the package file

Provided they exist on GitHub, most packages can be specified in [TOML](https://toml.io/en/). Documentation on the schema is [here](./docs/callToml.md).

As an example, let's look the testing library [`hedgehog`](https://github.com/stefan-hoeck/idris2-hedgehog).

```toml
#packages/hedgehog.toml
name = "hedgehog"
version = "0.0.4"

[ source ]
owner = "stefan-hoeck"
repo = "idris2-hedgehog"
rev = "929b27c4a58111b4d1327abb18a2eee4ad304f48"
# sha256 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

[ depends ]
idrisLibs = [ "elab-util", "sop", "pretty-show" ]
```

`rev` is the specific git commit to build against. `sha256` is the hash of an internal Nix file, and the typical way to get it is to try to build without one.
Nix flakes only use files tracked by git, so stage any new files and build the new package:

```
$ git add packages/hedgehog.toml
$ nix build .#hedgehog
error: hash mismatch in fixed-output derivation '/nix/store/8vhk935pzml87jj620kqhc0avkj474x2-source.drv':
 specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
 got:    sha256-Ev9LldllXHciUNHU8CcXrciW1WdxN8iW3J0kJwjsqjI=
error: 1 dependencies of derivation '/nix/store/42ypyrqdwwirzpnz2vcw0c9d6c0jyzvk-hedgehog.drv' failed to build
```

Just copy the correct sha256 and paste it into our `package/hedgehog.toml`.

```patch
# package/hedgehog.toml
  rev = "63e614776db3accebbcf4b64ac7a76e66e233e64"
- # sha256 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
+ sha256 = "Ev9LldllXHciUNHU8CcXrciW1WdxN8iW3J0kJwjsqjI="

```
And we're done! Stage and commit your changes and make a PR.

### Update a package

Assuming no dependencies have changed, a version bump in a TOML file is very easy.
 - Update the version number
 - Update `rev` to point to the target commit
 - Remove the old `sha256`
 - Run a build command
 - Get the correct `sha256`


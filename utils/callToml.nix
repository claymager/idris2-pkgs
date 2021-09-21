{ lib, pkgs, buildIdris, idris2Pkgs, fetchFromGitHub }:

let
  # loadTOML : File -> TomlDec
  loadTOML = file:
    let
      contents = builtins.fromTOML (builtins.readFile file);
      isLocal = (contents.source.host or "") == "local";
    in
    # If the TOML describes a package whose source is given with a relative path, we'll
      # need the absolute path to the file.
    lib.recursiveUpdate contents
      (if isLocal then { source._parent = builtins.dirOf file; } else { });

  # gets the source described in a TOML file
  # Switches on "source.host", with github as default.
  fetchers = sourceDesc:
    let
      sourceTypes = {
        github = fetchFromGitHub;
        local = { path ? ".", _parent }:
          if lib.hasPrefix "/" path
          then /. + path
          else _parent + ("/" + path);
      };
      host = sourceDesc.host or "github";
      args = builtins.removeAttrs sourceDesc [ "host" ];
    in
    sourceTypes.${host} args;

  # cleanTOML : [Gamma] -> AttrSet Ipkgs -> (SourceDec -> Source) -> TomlDec -> IdrisDec
  cleanTOML = extraPkgs: fetchSource: toml:
    let ipkgs = lib.recursiveUpdate idris2Pkgs extraPkgs; in
    lib.filterAttrs (n: v: v != null) {
      # (bare)
      name = toml.name;
      version = toml.version or null;
      codegen = toml.codegen or null;
      ipkgFile = toml.ipkgFile or null;
      executable = toml.executable or null;

      # [ source ]
      src = fetchSource toml.source;

      # [ patch ]
      preBuild = toml.patch.preBuild or null;
      postBuild = toml.patch.postBuild or null;
      preBinInstall = toml.patch.preBinInstall or null;
      postBinInstall = toml.patch.postBinInstall or null;
      preLibInstall = toml.patch.preLibInstall or null;
      postLibInstall = toml.patch.postLibInstall or null;

      # [ test ]
      doCheck = toml.test.enable or null;
      checkCommand = toml.test.command or null;
      preCheck = toml.test.preTest or null;
      postCheck = toml.test.postTest or null;
      # Map strings from TOML to Idris Libraries
      idrisTestLibraries = map (lib: ipkgs.${lib}) (toml.test.idrisLibs or [ ]);
      #                              ^- an error here may be a typo in [test] idrisLibs

      # [ depends ]
      # Map strings from TOML to nixpkgs packages
      buildInputs = map (p: pkgs.${p}) (toml.depends.buildInputs or [ ]);
      #                     ^- an error here may be a typo in buildDep entries

      # Map strings from TOML to nixpkgs packages, used only at build time
      nativeBuildInputs = map (p: pkgs.${p}) (toml.depends.nativeBuildInputs or [ ]);

      # Map strings from TOML to Idris Libraries
      idrisLibraries = map (lib: ipkgs.${lib}) (toml.depends.idrisLibs or [ ]);
      #                          ^- an error here may be a typo in [depends] idrisLibs

      # [ meta ]
      meta = toml.meta or { };

    };
in

rec {
  extendCallTOML = extraPkgs: file:
    buildIdris (cleanTOML extraPkgs fetchers (loadTOML file));

  callTOML = file: extendCallTOML { } file;

  buildTOMLSource = dir: file:
    lib.warn "buildTOMLSource is deprecated: please set [ source ] and use callTOML"
      (buildIdris (cleanTOML { } (_: dir) (loadTOML file)));
}

let patches = {
  chez = ''
    # No special treatment for Darwin: we don't have zsh in PATH.
    sed 's/Darwin/FakeSystem/' -i $file;

    # We don't need these anymore
    rm "$file"_app/compileChez "$file"_app/$(basename $file).ss
  '';
}; in
codegen: patches.${codegen} or ""

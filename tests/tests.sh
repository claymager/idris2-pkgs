#! /usr/bin/env bash

set -euo pipefail

# Go to parent directory
cd $(dirname $0)/../
export GIT_HOME=$(pwd)

printf "*** Building all packages...\n" >& 2
nix-build all-drvs.nix --no-out-link --keep-going

printf "*** Default nix shell grants an idris compiler...\n" >& 2
nix shell --command idris2 --check

printf "*** Nix shell works for idris2.withLibs...\n" >& 2
nix shell \
    --ignore-environment \
    .#idris2.withLibs.comonad.idrall \
    --command idris2 --check -p comonad -p idrall

printf "*** Building template...\n" >& 2
cd templates/simple
nix build .#runTests \
    --no-link --no-write-lock-file \
    --override-input idris2-pkgs ../..
cd ../..

for testdir in $(ls -d tests/*/); do
    printf "*** Testing $testdir ...\n" >&2
    $testdir/run
done

printf "\n*** Finished successfully\n" >&2

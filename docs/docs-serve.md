# Documentation Server

Literally just a small wrapper for `python -m http.server`, this utility needs a lot of help.

It's root is a bare directory (no index file) containing the `idris2 --mkdoc <pkg>` output for each
dependency of wichever package `_builders.devEnv` was called on.


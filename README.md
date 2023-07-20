[API reference](https://ocaml-multicore.github.io/multicore-magic/doc/multicore-magic/Multicore_magic/index.html)

# **multicore-magic** &mdash; Low-level multicore utilities for OCaml

This is a library of magic multicore utilities intended for experts for
extracting the best possible performance from multicore OCaml.

Hopefully future releases of multicore OCaml will make this library obsolete!

## Development

### Formatting

This project uses [ocamlformat](https://github.com/ocaml-ppx/ocamlformat) (for
OCaml) and [prettier](https://prettier.io/) (for Markdown).

### To make a new release

1. Update [CHANGES.md](CHANGES.md).
2. Run `dune-release tag VERSION` to create a tag for the new `VERSION`.
3. Run `dune-release` to publish the new `VERSION`.
4. Run `./update-gh-pages-for-tag VERSION` to update the online documentation.

# Release notes

All notable changes to this project will be documented in this file.

## 2.0.0

- Changed the semantics of `copy_as_padded` to not always copy and to not
  guarantee that `length_of_padded_array*` works with it. These semantic changes
  allow better use of the OCaml allocator to guarantee cache friendly alignment.
  (@polytypic)

## 1.0.1

- Ported the library to OCaml 4 (@polytypic)
- License changed to ISC from 0BSD (@tarides)

## 1.0.0

- Initial release (@polytypic)

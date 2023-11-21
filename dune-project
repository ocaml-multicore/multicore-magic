(lang dune 3.3)

(name multicore-magic)

(generate_opam_files true)

(source
 (github ocaml-multicore/multicore-magic))

(authors "Vesa Karvonen <vesa.a.j.k@gmail.com>")

(maintainers "Vesa Karvonen <vesa.a.j.k@gmail.com>")

(homepage "https://github.com/ocaml-multicore/multicore-magic")

(license ISC)

(package
 (name multicore-magic)
 (synopsis "Low-level multicore utilities for OCaml")
 (depends
  (ocaml
   (>= 4.12.0))
  (alcotest
   (and
    (>= 1.7.0)
    :with-test))
  (odoc
   (and
    (>= 2.2.0)
    :with-doc))))

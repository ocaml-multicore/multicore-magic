(lang dune 3.14)

(name multicore-magic)

(generate_opam_files true)

(implicit_transitive_deps false)

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
  ;; Test dependencies
  (domain_shims
   (and
    (>= 0.1.0)
    :with-test))
  (alcotest
   (and
    (>= 1.7.0)
    :with-test))
  ;; Documentation dependencies
  (sherlodoc
   (and
    (>= 0.2)
    :with-doc))
  (odoc
   (and
    (>= 2.4.1)
    :with-doc))))

(package
 (name multicore-magic-dscheck)
 (synopsis
  "A implementation of multicore-magic API using the atomic module of DScheck to make DScheck tests possible in libraries using multicore-magic")
 (depends
  (ocaml
   (>= 4.12.0))
  ;; Test dependencies
  (multicore-magic
   (>= 2.2.0))))

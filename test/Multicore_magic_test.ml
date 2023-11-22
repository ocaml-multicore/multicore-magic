let can_pad_int () = assert (Multicore_magic.copy_as_padded 101 = 101)
let can_pad_ref () = assert (!(Multicore_magic.copy_as_padded (ref 101)) = 101)

let can_pad_atomic () =
  assert (Atomic.get (Multicore_magic.copy_as_padded (Atomic.make 42)) = 42)

let can_pad_records () =
  let open struct
    type record = { foo : int; bar : int Atomic.t; baz : float }
  end in
  let foo = 42 and bar = Atomic.make 101 and baz = 9.6 in
  let x = Multicore_magic.copy_as_padded { foo; bar; baz } in
  assert (x.foo = foo && x.bar == bar && x.baz == baz)

let can_pad_float_record () =
  let open struct
    type record = { foo : float; bar : float; baz : float }
  end in
  let foo = 4.2 and bar = 10.1 and baz = 9.6 in
  let x = Multicore_magic.copy_as_padded { foo; bar; baz } in
  assert (x.foo = foo && x.bar = bar && x.baz = baz)

let can_pad_variants () =
  let open struct
    type variant = Foo of int * int Atomic.t
  end in
  let foo = 19 and bar = Atomic.make 76 in
  let (Foo (foo', bar')) = Multicore_magic.copy_as_padded (Foo (foo, bar)) in
  assert (foo = foo' && bar == bar')

let can_pad_arrays () =
  let xs = Multicore_magic.make_padded_array 5 101 in
  assert (5 <= Array.length xs);
  for i = 0 to 4 do
    assert (xs.(i) = 101)
  done

let padded_array_length () =
  assert (
    Multicore_magic.length_of_padded_array
      (Multicore_magic.make_padded_array 42 0)
    = 42)

let padded_array_length_minus_1 () =
  assert (
    Multicore_magic.length_of_padded_array_minus_1
      (Multicore_magic.make_padded_array 101 0)
    = 100)

let can_pad_float_arrays () =
  let x = 4.2 in
  let xs = Multicore_magic.make_padded_array 5 x in
  assert (5 <= Array.length xs);
  for i = 0 to 4 do
    assert (xs.(i) = x)
  done;
  assert (Multicore_magic.length_of_padded_array xs = 5)

let fenceless_get () =
  assert (Multicore_magic.fenceless_get (Atomic.make 42) = 42)

let fenceless_set () =
  let x = Atomic.make 42 in
  Multicore_magic.fenceless_set x 101;
  assert (Multicore_magic.fenceless_get x = 101);
  assert (Atomic.get x = 101)

let fence () =
  assert (
    let atomic = Atomic.make 76 in
    Multicore_magic.fence atomic;
    Atomic.get atomic = 76)

let transparent_atomic v0 v1 v2 () =
  let x = Multicore_magic.Transparent_atomic.make_contended v0 in
  assert (v0 = Multicore_magic.Transparent_atomic.fenceless_get x);
  assert (v0 = Multicore_magic.Transparent_atomic.get x);
  Multicore_magic.Transparent_atomic.set x v1;
  assert (v1 = Multicore_magic.Transparent_atomic.fenceless_get x);
  assert (v1 = Multicore_magic.Transparent_atomic.get x);
  Multicore_magic.Transparent_atomic.fenceless_set x v2;
  assert (v2 = Multicore_magic.Transparent_atomic.fenceless_get x);
  assert (v2 = Multicore_magic.Transparent_atomic.get x)

let test_domain_hash () = assert (Multicore_magic.domain_hash () = 0)

let () =
  Alcotest.run "multicore-magic"
    [
      ("can pad int", [ Alcotest.test_case "" `Quick can_pad_int ]);
      ("can pad ref", [ Alcotest.test_case "" `Quick can_pad_ref ]);
      ("can pad atomic", [ Alcotest.test_case "" `Quick can_pad_atomic ]);
      ("can pad records", [ Alcotest.test_case "" `Quick can_pad_records ]);
      ( "can pad float record",
        [ Alcotest.test_case "" `Quick can_pad_float_record ] );
      ("can pad variants", [ Alcotest.test_case "" `Quick can_pad_variants ]);
      ("can pad arrays", [ Alcotest.test_case "" `Quick can_pad_arrays ]);
      ( "padded array length",
        [ Alcotest.test_case "" `Quick padded_array_length ] );
      ( "padded array length - 1",
        [ Alcotest.test_case "" `Quick padded_array_length_minus_1 ] );
      ( "can pad float arrays",
        [ Alcotest.test_case "" `Quick can_pad_float_arrays ] );
      ("fenceless_get", [ Alcotest.test_case "" `Quick fenceless_get ]);
      ("fenceless_set", [ Alcotest.test_case "" `Quick fenceless_set ]);
      ("fence", [ Alcotest.test_case "" `Quick fence ]);
      ( "transparent_atomic with floats",
        [ Alcotest.test_case "" `Quick (transparent_atomic 4.2 1.01 7.6) ] );
      ( "transparent_atomic with ints",
        [ Alcotest.test_case "" `Quick (transparent_atomic 42 101 76) ] );
      ("domain_hash", [ Alcotest.test_case "" `Quick test_domain_hash ]);
    ]

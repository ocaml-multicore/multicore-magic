let can_pad_ref () = assert (!(Multicore_magic.copy_as_padded (ref 101)) = 101)

let can_pad_atomic () =
  assert (Atomic.get (Multicore_magic.copy_as_padded (Atomic.make 42)) = 42)

let can_pad_records () =
  let open struct
    type record = { foo : int; bar : int Atomic.t }
  end in
  let foo = 42 and bar = Atomic.make 101 in
  let x = Multicore_magic.copy_as_padded { foo; bar } in
  assert (x.foo = foo && x.bar == bar)

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

let () =
  Alcotest.run "multicore-magic"
    [
      ("can pad ref", [ Alcotest.test_case "" `Quick can_pad_ref ]);
      ("can pad atomic", [ Alcotest.test_case "" `Quick can_pad_atomic ]);
      ("can pad records", [ Alcotest.test_case "" `Quick can_pad_records ]);
      ("can pad variants", [ Alcotest.test_case "" `Quick can_pad_variants ]);
      ("can pad arrays", [ Alcotest.test_case "" `Quick can_pad_arrays ]);
      ( "padded array length",
        [ Alcotest.test_case "" `Quick padded_array_length ] );
      ( "padded array length - 1",
        [ Alcotest.test_case "" `Quick padded_array_length_minus_1 ] );
      ("fenceless_get", [ Alcotest.test_case "" `Quick fenceless_get ]);
      ("fenceless_set", [ Alcotest.test_case "" `Quick fenceless_set ]);
      ("fence", [ Alcotest.test_case "" `Quick fence ]);
    ]

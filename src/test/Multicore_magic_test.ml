let () = assert (!(Multicore_magic.copy_as_padded (ref 101)) = 101)

let () =
  assert (Atomic.get (Multicore_magic.copy_as_padded (Atomic.make 42)) = 42)

let () =
  let open struct
    type record = {foo : int; bar : int Atomic.t}
  end in
  let foo = 42 and bar = Atomic.make 101 in
  let x = Multicore_magic.copy_as_padded {foo; bar} in
  assert (x.foo = foo && x.bar == bar)

let () =
  let open struct
    type variant = Foo of int * int Atomic.t
  end in
  let foo = 19 and bar = Atomic.make 76 in
  let (Foo (foo', bar')) = Multicore_magic.copy_as_padded (Foo (foo, bar)) in
  assert (foo = foo' && bar == bar')

let () =
  let xs = Multicore_magic.make_padded_array 5 101 in
  assert (5 <= Array.length xs);
  for i = 0 to 4 do
    assert (xs.(i) = 101)
  done

let () =
  assert (
    Multicore_magic.length_of_padded_array
      (Multicore_magic.make_padded_array 42 0)
    = 42)

let () =
  assert (
    Multicore_magic.length_of_padded_array_minus_1
      (Multicore_magic.make_padded_array 101 0)
    = 100)

let () = assert (Multicore_magic.fenceless_get (Atomic.make 42) = 42)

let () =
  let x = Atomic.make 42 in
  Multicore_magic.fenceless_set x 101;
  assert (Multicore_magic.fenceless_get x = 101);
  assert (Atomic.get x = 101)

let () =
  assert (
    let atomic = Atomic.make 76 in
    Multicore_magic.fence atomic;
    Atomic.get atomic = 76)

module Atomic = Dscheck.TracedAtomic

type 'a t = 'a Atomic.t array

let[@inline] at (type a) (xs : a t) i : a Atomic.t =
  (* ['a t] does not contain [float]s. *)
  Obj.magic (Array.unsafe_get (Obj.magic xs : a ref array) i)

let[@inline] make n v = Array.init n @@ fun _ -> Atomic.make v
let[@inline] init n fn = Array.init n @@ fun i -> Atomic.make (fn i)
let[@inline] of_array xs = init (Array.length xs) (Array.unsafe_get xs)

external length : 'a array -> int = "%array_length"

let[@inline] unsafe_fenceless_set xs i v = Obj.magic (at xs i) := v
let[@inline] unsafe_fenceless_get xs i = !(Obj.magic (at xs i))

let[@inline] unsafe_compare_and_set xs i b a =
  Atomic.compare_and_set (at xs i) b a

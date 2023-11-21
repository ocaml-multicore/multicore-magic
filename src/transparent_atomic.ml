type 'a t = 'a ref

open struct
  external as_atomic : 'a t -> 'a Atomic.t = "%identity"
  external of_atomic : 'a Atomic.t -> 'a t = "%identity"
end

let[@inline] make x = of_atomic (Atomic.make x)

let[@inline] make_contended x =
  of_atomic (Padding.copy_as_padded (Atomic.make x))

let[@inline] get x = Atomic.get (Sys.opaque_identity (as_atomic x))
let[@inline] fenceless_get x = !(Sys.opaque_identity x)
let[@inline] compare_and_set x b a = Atomic.compare_and_set (as_atomic x) b a
let[@inline] exchange x v = Atomic.exchange (as_atomic x) v
let[@inline] set x v = Atomic.set (as_atomic x) v
let[@inline] fenceless_set x v = x := v
let[@inline] fetch_and_add x v = Atomic.fetch_and_add (as_atomic x) v
let[@inline] incr x = Atomic.incr (as_atomic x)
let[@inline] decr x = Atomic.decr (as_atomic x)

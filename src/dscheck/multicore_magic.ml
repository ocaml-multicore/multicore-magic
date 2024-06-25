module Atomic = Dscheck.TracedAtomic

let copy_as_padded = Fun.id
let copy_as ?padded:_ x = x
let make_padded_array = Array.make
let length_of_padded_array = Array.length
let length_of_padded_array_minus_1 xs = Array.length xs - 1

module Transparent_atomic = struct
  include Atomic

  let make_contended = make
  let fenceless_get = get
  let fenceless_set = set
end

let fenceless_get = Atomic.get
let fenceless_set = Atomic.set
let[@inline] fence atomic = Atomic.fetch_and_add atomic 0 |> ignore

module Atomic_array = struct
  type 'a t = 'a Atomic.t array

  let[@inline] at (xs : 'a t) i : 'a Atomic.t = Array.get xs i
  let[@inline] make n v = Array.init n @@ fun _ -> Atomic.make v
  let[@inline] init n fn = Array.init n @@ fun i -> Atomic.make (fn i)
  let[@inline] of_array xs = init (Array.length xs) (Array.get xs)

  external length : 'a array -> int = "%array_length"

  let unsafe_fenceless_set xs i v = Atomic.set xs.(i) v
  let unsafe_fenceless_get xs i = Atomic.get xs.(i)

  let[@inline] unsafe_compare_and_set xs i b a =
    Atomic.compare_and_set (at xs i) b a
end

let instantaneous_domain_index () = 0

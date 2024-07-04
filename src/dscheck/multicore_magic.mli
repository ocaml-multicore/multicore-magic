module Atomic = Dscheck.TracedAtomic

val copy_as_padded : 'a -> 'a
val copy_as : ?padded:bool -> 'a -> 'a
val make_padded_array : int -> 'a -> 'a array
val length_of_padded_array : 'a array -> int
val length_of_padded_array_minus_1 : 'a array -> int
val fenceless_get : 'a Atomic.t -> 'a
val fenceless_set : 'a Atomic.t -> 'a -> unit
val fence : int Atomic.t -> unit

module Transparent_atomic : sig
  type !'a t = 'a Atomic.t

  val make : 'a -> 'a t
  val make_contended : 'a -> 'a t
  val get : 'a t -> 'a
  val fenceless_get : 'a t -> 'a
  val set : 'a t -> 'a -> unit
  val fenceless_set : 'a t -> 'a -> unit
  val exchange : 'a t -> 'a -> 'a
  val compare_and_set : 'a t -> 'a -> 'a -> bool
  val fetch_and_add : int t -> int -> int
  val incr : int t -> unit
  val decr : int t -> unit
end

module Atomic_array : sig
  type !'a t

  val make : int -> 'a -> 'a t
  val of_array : 'a array -> 'a t
  val init : int -> (int -> 'a) -> 'a t
  val length : 'a t -> int
  val unsafe_fenceless_get : 'a t -> int -> 'a
  val unsafe_fenceless_set : 'a t -> int -> 'a -> unit
  val unsafe_compare_and_set : 'a t -> int -> 'a -> 'a -> bool
end

val instantaneous_domain_index : unit -> int

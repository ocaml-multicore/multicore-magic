(** This is a library of magic multicore utilities intended for experts for
    extracting the best possible performance from multicore OCaml.

    Hopefully future releases of multicore OCaml will make this library
    obsolete! *)

(** {1 Helpers for using padding to avoid false sharing} *)

val copy_as_padded : 'a -> 'a
(** Depending on the object, either creates a shallow clone of it or returns it
    as is.  When cloned, the clone will have extra padding words added after the
    last used word.

    This is designed to help avoid
    {{:https://en.wikipedia.org/wiki/False_sharing} false sharing}.  False
    sharing has a negative impact on multicore performance.  Accesses of both
    atomic and non-atomic locations, whether read-only or read-write, may suffer
    from false sharing.

    The intended use case for this is to pad all long lived objects that are
    being accessed highly frequently (read or written).

    Many kinds of objects can be padded, for example:

    {[
      let padded_atomic = Multicore_magic.copy_as_padded (Atomic.make 101)

      let padded_ref = Multicore_magic.copy_as_padded (ref 42)

      let padded_record = Multicore_magic.copy_as_padded {
        number = 76;
        pointer = 1 :: 2 :: 3 :: [];
      }

      let padded_variant = Multicore_magic.copy_as_padded (Some 1)
    ]}

    Padding changes the length of an array.  If you need to pad an array, use
    {!make_padded_array}. *)

val copy_as : ?padded:bool -> 'a -> 'a
(** [copy_as x] by default simply returns [x].  When [~padded:true] is
    explicitly specified, returns {{!copy_as_padded} [copy_as_padded x]}. *)

val make_padded_array : int -> 'a -> 'a array
(** Creates a padded array.  The length of the returned array includes padding.
    Use {!length_of_padded_array} to get the unpadded length. *)

val length_of_padded_array : 'a array -> int
(** Returns the length of an array created by {!make_padded_array} without the
    padding.

    {b WARNING}: This is not guaranteed to work with {!copy_as_padded}. *)

val length_of_padded_array_minus_1 : 'a array -> int
(** Returns the length of an array created by {!make_padded_array} without the
    padding minus 1.

    {b WARNING}: This is not guaranteed to work with {!copy_as_padded}. *)

(** {1 Missing [Atomic] operations} *)

val fenceless_get : 'a Atomic.t -> 'a
(** Get a value from the atomic without performing an acquire fence.

    Consider the following prototypical example of a lock-free algorithm:

    {[
      let rec prototypical_lock_free_algorithm () =
        let expected = Atomic.get atomic in
        let desired = (* computed from expected *) in
        if not (Atomic.compare_and_set atomic expected desired) then
          (* failure, maybe retry *)
        else
          (* success *)
    ]}

    A potential performance problem with the above example is that it performs
    two acquire fences.  Both the [Atomic.get] and the [Atomic.compare_and_set]
    perform an acquire fence.  This may have a negative impact on performance.

    Assuming the first fence is not necessary, we can rewrite the example using
    {!fenceless_get} as follows:

    {[
      let rec prototypical_lock_free_algorithm () =
        let expected = Multicore_magic.fenceless_get atomic in
        let desired = (* computed from expected *) in
        if not (Atomic.compare_and_set atomic expected desired) then
          (* failure, maybe retry *)
        else
          (* success *)
    ]}

    Now only a single acquire fence is performed by [Atomic.compare_and_set] and
    performance may be improved. *)

val fenceless_set : 'a Atomic.t -> 'a -> unit
(** Set the value of an atomic without performing a full fence.

    Consider the following example:

    {[
      let new_atomic = Atomic.make dummy_value in
      (* prepare data_structure referring to new_atomic *)
      Atomic.set new_atomic data_structure;
      (* publish the data_structure: *)
      Atomic.exchance old_atomic data_structure
    ]}

    A potential performance problem with the above example is that it performs
    two full fences.  Both the [Atomic.set] used to initialize the data
    structure and the [Atomic.exchange] used to publish the data structure
    perform a full fence.  The same would also apply in cases where
    [Atomic.compare_and_set] or [Atomic.set] would be used to publish the data
    structure.  This may have a negative impact on performance.

    Using {!fenceless_set} we can rewrite the example as follows:

    {[
      let new_atomic = Atomic.make dummy_value in
      (* prepare data_structure referring to new_atomic *)
      Multicore_magic.fenceless_set new_atomic data_structure;
      (* publish the data_structure: *)
      Atomic.exchance old_atomic data_structure
    ]}

    Now only a single full fence is performed by [Atomic.exchange] and
    performance may be improved. *)

val fence : int Atomic.t -> unit
(** Perform a full acquire-release fence on the given atomic.

    [fence atomic] is equivalent to [ignore (Atomic.fetch_and_add atomic 0)]. *)

(** {1 Fixes and workarounds} *)

module Transparent_atomic : sig
  (** A replacement for [Stdlib.Atomic] with fixes and performance improvements

      [Stdlib.Atomic.get] is incorrectly subject to CSE optimization in OCaml
      5.0.0 and 5.1.0.  This can result in code being generated that can produce
      results that cannot be explained with the OCaml memory model.  It can also
      sometimes result in code being generated where a manual optimization to
      avoid writing to memory is defeated by the compiler as the compiler
      eliminates a (repeated) read access.  This module implements {!get} such
      that argument to [Stdlib.Atomic.get] is passed through
      [Sys.opaque_identity], which prevents the compiler from applying the CSE
      optimization.

      OCaml 5 generates inefficient accesses of ['a Stdlib.Atomic.t array]s
      assuming that the array might be an array of [float]ing point numbers.
      That is because the [Stdlib.Atomic.t] type constructor is opaque, which
      means that the compiler cannot assume that [_ Stdlib.Atomic.t] is not the
      same as [float].  This module defines {{!t} the type} as [private 'a ref],
      which allows the compiler to know that it cannot be the same as [float],
      which allows the compiler to generate more efficient array accesses.  This
      can both improve performance and reduce size of generated code when using
      arrays of atomics. *)

  type !'a t = private 'a ref

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

(** {1 Missing functionality} *)

module Atomic_array : sig
  (** Array of (potentially unboxed) atomic locations.

      Where available, this uses an undocumented operation exported by the OCaml
      5 runtime,
      {{:https://github.com/ocaml/ocaml/blob/7a5d882d22cdd32b6319e9be680bd1a3d67377a9/runtime/memory.c#L313-L338}
      [caml_atomic_cas_field]}, which makes it possible to perform sequentially
      consistent atomic updates of record fields and array elements.

      Hopefully a future version of OCaml provides more comprehensive and even
      more efficient support for both sequentially consistent and relaxed atomic
      operations on records and arrays. *)

  type !'a t
  (** Represents an array of atomic locations. *)

  val make : int -> 'a -> 'a t
  (** [make n value] creates a new array of [n] atomic locations having given
      [value]. *)

  val of_array : 'a array -> 'a t
  (** [of_array non_atomic_array] create a new array of atomic locations as a
      copy of the given [non_atomic_array]. *)

  val init : int -> (int -> 'a) -> 'a t
  (** [init n fn] is equivalent to {{!of_array} [of_array (Array.init n fn)]}. *)

  val length : 'a t -> int
  (** [length atomic_array] returns the length of the [atomic_array]. *)

  val unsafe_fenceless_get : 'a t -> int -> 'a
  (** [unsafe_fenceless_get atomic_array index] reads and returns the value at
      the specified [index] of the [atomic_array].

      ⚠️ The read is {i relaxed} and may be reordered with respect to other reads
      and writes in program order.

      ⚠️ No bounds checking is performed. *)

  val unsafe_fenceless_set : 'a t -> int -> 'a -> unit
  (** [unsafe_fenceless_set atomic_array index value] writes the given [value]
      to the specified [index] of the [atomic_array].

      ⚠️ The write is {i relaxed} and may be reordered with respect to other
      reads and (non-initializing) writes in program order.

      ⚠️ No bounds checking is performed. *)

  val unsafe_compare_and_set : 'a t -> int -> 'a -> 'a -> bool
  (** [unsafe_compare_and_set atomic_array index before after] atomically
      updates the specified [index] of the [atomic_array] to the [after] value
      in case it had the [before] value and returns a boolean indicating whether
      that was the case.  This operation is {i sequentially consistent} and may
      not be reordered with respect to other reads and writes in program order.

      ⚠️ No bounds checking is performed. *)
end

(** {1 Avoiding contention} *)

val instantaneous_domain_index : unit -> int
(** [instantaneous_domain_index ()] potentially (re)allocates and returns a
    non-negative integer "index" for the current domain.  The indices are
    guaranteed to be unique among the domains that exist at a point in time.
    Each call of [instantaneous_domain_index ()] may return a different index.

    The intention is that the returned value can be used as an index into a
    contention avoiding parallelism safe data structure.  For example, a naïve
    scalable increment of one counter from an array of counters could be done as
    follows:

    {[
      let incr counters =
        (* Assuming length of [counters] is a power of two and larger than
           the number of domains. *)
        let mask = Array.length counters - 1 in
        let index = instantaneous_domain_index () in
        Atomic.incr counters.(index land mask)
    ]}

    The implementation ensures that the indices are allocated as densely as
    possible at any given moment.  This should allow allocating as many counters
    as needed and essentially eliminate contention.

    On OCaml 4 [instantaneous_domain_index ()] will always return [0]. *)

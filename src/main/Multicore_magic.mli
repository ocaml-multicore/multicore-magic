(** This is a library of magic multicore utilities intended for experts for
    extracting the best possible performance from multicore OCaml.

    Hopefully future releases of multicore OCaml will make this library
    obsolete! *)

(** {1 Helpers for using padding to avoid false sharing} *)

val copy_as_padded : 'a -> 'a
(** Creates a shallow clone of the given object.  The clone will have extra
    padding words added after the last used word.

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

    let padded_array = Multicore_magic.copy_as_padded [|3; 1; 4|]
]}

    Padding changes the length of an array, see {!length_of_padded_array}. *)

val make_padded_array : int -> 'a -> 'a array
(** Creates a padded array.  The length of the returned array includes padding.
    Use {!length_of_padded_array} to get the unpadded length. *)

val length_of_padded_array : 'a array -> int
(** Returns the length of a padded array without the padding. *)

val length_of_padded_array_minus_1 : 'a array -> int
(** Returns the length of a padded array without the padding minus 1. *)

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

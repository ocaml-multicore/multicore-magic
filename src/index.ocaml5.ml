open struct
  module Atomic = Transparent_atomic

  (** We don't use the sign bit. *)
  let bits_per_word = Sys.int_size - 1

  let bit_index_of b =
    (* As [b] contains exactly one non-zero bit, this could directly be optimized
       using techniques described in

         Using de Bruijn Sequences to Index a 1 in a Computer Word
         by Leiserson, Prokop, and Randall. *)
    let i, b =
      if 32 < Sys.int_size && 1 lsl 0x20 <= b then (0x20, b lsr 0x20) else (0, b)
    in
    let i, b = if 1 lsl 0x10 <= b then (i + 0x10, b lsr 0x10) else (i, b) in
    let i, b = if 1 lsl 0x08 <= b then (i + 0x08, b lsr 0x08) else (i, b) in
    let i, b = if 1 lsl 0x04 <= b then (i + 0x04, b lsr 0x04) else (i, b) in
    let i, b = if 1 lsl 0x02 <= b then (i + 0x02, b lsr 0x02) else (i, b) in
    if 1 lsl 0x01 <= b then i + 0x01 else i

  module Index_allocator : sig
    type t

    val create : unit -> t
    val acquire : t -> int
    val release : t -> int -> unit
  end = struct
    type t = int Atomic.t array Atomic.t

    let create () = Atomic.make [||]

    let release words bit_index =
      let word_index = bit_index / bits_per_word in
      let t = Atomic.get words in
      let bit = 1 lsl (bit_index - (word_index * bits_per_word)) in
      let word = Array.unsafe_get t word_index in
      Atomic.fetch_and_add word (-bit) |> ignore

    let rec acquire_rec words t i =
      if i < Array.length t then
        let word = Array.unsafe_get t i in
        let before = Atomic.get word in
        let alloc = before + 1 in
        (* We don't use the sign bit. *)
        if 0 < alloc then begin
          let after = alloc lor before in
          if Atomic.compare_and_set word before after then
            (i * bits_per_word) + bit_index_of (after lxor before)
          else acquire_rec words t i
        end
        else acquire_rec words t (i + 1)
      else
        let new_t =
          Array.init ((Array.length t * 2) + 1) @@ fun i ->
          if i < Array.length t then Array.unsafe_get t i else Atomic.make 0
        in
        Atomic.compare_and_set words t new_t |> ignore;
        acquire words

    and acquire words = acquire_rec words (Atomic.get words) 0
  end

  module Domain_index_allocator : sig
    type t
    type domain

    val create : unit -> t
    val set_on_first_get : t -> (t -> domain -> unit) -> unit
    val new_domain : unit -> domain
    val delete_domain : t -> domain -> unit
    val get : t -> domain -> int
  end = struct
    type domain = int ref

    type t = {
      mutable _num_domains : int;
      index_allocator : Index_allocator.t;
      mutable on_first_get : t -> domain -> unit;
    }

    external num_domains_as_atomic : t -> int Atomic.t = "%identity"

    let on_first_get _ _ = ()

    let create () =
      let index_allocator = Index_allocator.create () in
      { _num_domains = 0; index_allocator; on_first_get }
      |> Padding.copy_as_padded

    let set_on_first_get t on_first_get = t.on_first_get <- on_first_get

    let unallocated_index = Int.max_int
    and domain_exit_index = Int.max_int - 1

    let new_domain () = ref unallocated_index |> Padding.copy_as_padded

    let delete_domain t domain =
      let index = !domain in
      if index < domain_exit_index then begin
        domain := domain_exit_index;
        Index_allocator.release t.index_allocator index;
        Atomic.decr (num_domains_as_atomic t)
      end

    let[@poll error] [@inline never] cas_domain domain before after =
      !domain == before
      && begin
        domain := after;
        true
      end

    let[@inline never] rec instantaneous_domain_index t domain =
      let index = !domain in
      if index < Atomic.get (num_domains_as_atomic t) then index
      else if index == domain_exit_index then
        failwith
          "Multicore_magic: instantaneous_domain_index called after domain exit"
      else
        let new_index = Index_allocator.acquire t.index_allocator in
        if
          new_index
          < Atomic.get (num_domains_as_atomic t)
            + Bool.to_int (index == unallocated_index)
          && cas_domain domain index new_index
        then begin
          if index == unallocated_index then begin
            Atomic.incr (num_domains_as_atomic t);
            t.on_first_get t domain
          end
          else Index_allocator.release t.index_allocator index;
          instantaneous_domain_index t domain
        end
        else begin
          Index_allocator.release t.index_allocator new_index;
          instantaneous_domain_index t domain
        end

    let[@inline] get t domain =
      let index = !domain in
      if index < Atomic.get (num_domains_as_atomic t) then index
      else instantaneous_domain_index t domain
  end

  let key = Domain.DLS.new_key Domain_index_allocator.new_domain
  let t = Domain_index_allocator.create ()

  let release_index () =
    let domain = Domain.DLS.get key in
    Domain_index_allocator.delete_domain t domain

  let () =
    Domain_index_allocator.set_on_first_get t @@ fun _ _ ->
    Domain.at_exit release_index
end

let instantaneous_domain_index () =
  let domain = Domain.DLS.get key in
  Domain_index_allocator.get t domain

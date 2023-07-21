let num_padding_words = 15

let copy_as_padded (o : 'a) : 'a =
  let o = Obj.repr o in
  let n = Obj.new_block (Obj.tag o) (Obj.size o + num_padding_words) in
  for i = 0 to Obj.size o - 1 do
    Obj.set_field n i (Obj.field o i)
  done;
  Obj.magic n

let make_padded_array n x =
  let a = Array.make (n + num_padding_words) (Obj.magic ()) in
  if x != Obj.magic () then Array.fill a 0 n x;
  a

let length_of_padded_array x = Array.length x - num_padding_words [@@inline]

let length_of_padded_array_minus_1 x = Array.length x - (num_padding_words + 1)
[@@inline]

let fenceless_get (atomic : 'a Atomic.t) = !(Obj.magic atomic : 'a ref)
[@@inline]

let fenceless_set (atomic : 'a Atomic.t) value =
  (Obj.magic atomic : 'a ref) := value
[@@inline]

let fence atomic = Atomic.fetch_and_add atomic 0 |> ignore [@@inline]

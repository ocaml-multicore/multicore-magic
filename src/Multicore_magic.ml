let num_padding_words = 15

let copy_as_padded (o : 'a) : 'a =
  let o = Obj.repr o in
  let n = Obj.new_block (Obj.tag o) (Obj.size o + num_padding_words) in
  for i = 0 to Obj.size o - 1 do
    Obj.set_field n i (Obj.field o i)
  done;
  Obj.magic n

let make_padded_array n x =
  let a = Array.make (n + num_padding_words) x in
  if Obj.is_block (Obj.repr x) && Obj.tag (Obj.repr x) != Obj.double_tag then
    Array.fill a n num_padding_words (Obj.magic ());
  a

let[@inline] length_of_padded_array x = Array.length x - num_padding_words

let[@inline] length_of_padded_array_minus_1 x =
  Array.length x - (num_padding_words + 1)

let[@inline] fenceless_get (atomic : 'a Atomic.t) = !(Obj.magic atomic : 'a ref)

let[@inline] fenceless_set (atomic : 'a Atomic.t) value =
  (Obj.magic atomic : 'a ref) := value

let[@inline] fence atomic = Atomic.fetch_and_add atomic 0 |> ignore

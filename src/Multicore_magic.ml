let num_padding_words = Cache.words_per_cache_line - 1

let copy_as_padded (o : 'a) : 'a =
  let o = Obj.repr o in
  if Obj.is_block o then begin
    let original_size = Obj.size o in
    let padded_size =
      if original_size <= num_padding_words then num_padding_words
      else original_size + num_padding_words
    in
    if original_size <> padded_size then begin
      let t = Obj.tag o in
      if Sys.word_size = 64 && t != Obj.double_array_tag then begin
        let n = Obj.new_block t padded_size in
        Array.blit (Obj.magic o) 0 (Obj.magic n) 0 original_size;
        Obj.magic n
      end
      else Obj.magic o
    end
    else Obj.magic o
  end
  else Obj.magic o

let make_padded_array n x =
  let a = Array.make (n + num_padding_words) x in
  if Obj.is_block (Obj.repr x) then
    Array.fill a n num_padding_words
      (if Obj.tag (Obj.repr x) == Obj.double_tag then Obj.magic 0.0
       else Obj.magic ());
  a

let[@inline] length_of_padded_array x = Array.length x - num_padding_words

let[@inline] length_of_padded_array_minus_1 x =
  Array.length x - (num_padding_words + 1)

let[@inline] fenceless_get (atomic : 'a Atomic.t) = !(Obj.magic atomic : 'a ref)

let[@inline] fenceless_set (atomic : 'a Atomic.t) value =
  (Obj.magic atomic : 'a ref) := value

let[@inline] fence atomic = Atomic.fetch_and_add atomic 0 |> ignore

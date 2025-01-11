let num_padding_words =
  if Sys.backend_type == Native || Sys.backend_type == Bytecode then
    Cache.words_per_cache_line - 1
  else
    (* Disables padding on special targets like js_of_ocaml. *)
    0

let copy_as_padded (o : 'a) : 'a =
  if num_padding_words = 0 then o
  else
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
          Array.blit (Obj.obj o) 0 (Obj.obj n) 0 original_size;
          Obj.obj n
        end
        else Obj.obj o
      end
      else Obj.obj o
    end
    else Obj.obj o

let copy_as ?padded x =
  if num_padding_words = 0 then x
  else
    match padded with None | Some false -> x | Some true -> copy_as_padded x

let make_padded_array n x =
  let a = Array.make (n + num_padding_words) x in
  if num_padding_words <> 0 && Obj.is_block (Obj.repr x) then
    Array.fill a n num_padding_words
      (if Obj.tag (Obj.repr x) == Obj.double_tag then Obj.magic 0.0
       else Obj.magic ());
  a

let[@inline] length_of_padded_array x = Array.length x - num_padding_words

let[@inline] length_of_padded_array_minus_1 x =
  Array.length x - (num_padding_words + 1)

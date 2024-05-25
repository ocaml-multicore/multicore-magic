type !'a t = 'a array

let[@inline] unsafe_fenceless_set xs i x =
  (* We never create [float array]s. *)
  Array.unsafe_set (Obj.magic xs : string array) i (Obj.magic x)

let[@inline never] make n x =
  (* We never create [float array]s. *)
  if Obj.tag (Obj.repr x) != Obj.double_tag then Array.make n x
  else
    let xs = Array.make n (Obj.magic ()) in
    for i = 0 to n - 1 do
      unsafe_fenceless_set xs i x
    done;
    xs

let[@inline never] init n fn =
  (* We never create [float array]s. *)
  let ys = Array.make n (Obj.magic ()) in
  for i = 0 to n - 1 do
    unsafe_fenceless_set ys i (fn i)
  done;
  ys

let[@inline never] of_array xs =
  if Obj.tag (Obj.repr xs) != Obj.double_array_tag then Array.copy xs
  else init (Array.length xs) (fun i -> Array.unsafe_get xs i)

external length : 'a array -> int = "%array_length"

let[@inline] unsafe_fenceless_get xs i =
  (* We never create [float array]s. *)
  Obj.magic
    (Sys.opaque_identity (Array.unsafe_get (Obj.magic xs : string array) i))

let[@inline] unsafe_compare_and_set xs i b a : bool =
  let open struct
    external unsafe_compare_and_set_as_int :
      'a array -> (int[@untagged]) -> 'a -> 'a -> (int[@untagged])
      = "caml_multicore_magic_atomic_array_cas" "caml_atomic_cas_field"
    [@@noalloc]
  end in
  Obj.magic (unsafe_compare_and_set_as_int xs i b a)

//Provides: caml_multicore_magic_atomic_array_cas
function caml_multicore_magic_atomic_array_cas(target, index, before, after) {
  index = index + 1
  const match = Object.is(target[index], before)
  if (match) target[index] = after
  return match
}

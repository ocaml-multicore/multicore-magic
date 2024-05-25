#include "caml/mlvalues.h"
#include "caml/memory.h"
#include "caml/alloc.h"

CAMLprim value caml_multicore_magic_atomic_array_cas(
  value obj, intnat field, value oldval, value newval)
{
  return Val_int(caml_atomic_cas_field(obj, Int_val(field), oldval, newval));
}

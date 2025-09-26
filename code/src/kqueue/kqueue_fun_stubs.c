#include <sys/event.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

void* ctypes_ptr(value v) {
  if (Is_block(v) && Tag_val(v) == Custom_tag) {
    return *((void**)Data_custom_val(v));
  } else if (Is_long(v)) {
    return (void*)Nativeint_val(v);
  } else {
    caml_failwith("Unknown pointer type");
  }
}

value caml_kqueue(value unit_val) {
  CAMLparam1(unit_val);
  CAMLlocal1(result);

  int k = kqueue();

  result = Val_int(k);
  CAMLreturn(result);
}

value caml_kevent(value v_k,
                  value v_changelist,
                  value v_nchanges,
                  value v_eventlist,
                  value v_nevents,
                  value v_timespec) {
  CAMLparam5(v_k, v_changelist, v_nchanges, v_eventlist, v_nevents);
  CAMLxparam1(v_timespec);
  CAMLlocal1(result);

  int k = Int_val(v_k);
  struct kevent *changelist = ctypes_ptr(v_changelist);
  int nchanges = Int_val(v_nchanges);
  struct kevent *eventlist = ctypes_ptr(v_eventlist);
  int nevents = Int_val(v_nevents);
  struct timespec *timeout = ctypes_ptr(v_timespec);

  int ret = kevent(k, changelist, nchanges, eventlist, nevents, timeout);

  result = Val_int(ret);
  CAMLreturn(result);
}

value caml_kevent_byte(value k,
                       value changelist,
                       value nchanges,
                       value eventlist,
                       value nevents,
                       value timespec) {
  return caml_kevent(k, changelist, nchanges, eventlist, nevents, timespec);
}

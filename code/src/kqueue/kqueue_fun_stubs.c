#include <sys/event.h>
#include <time.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/threads.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

void* of_fat_ptr(value v) {
  return (void*)Nativeint_val(Field(v, 1));
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
  struct kevent *changelist = of_fat_ptr(v_changelist);
  int nchanges = Int_val(v_nchanges);
  struct kevent *eventlist = of_fat_ptr(v_eventlist);
  int nevents = Int_val(v_nevents);
  struct timespec *timeout = of_fat_ptr(v_timespec);

  caml_release_runtime_system();

  int ret = kevent(k, changelist, nchanges, eventlist, nevents, timeout);

  caml_acquire_runtime_system();

  result = Val_int(ret);
  CAMLreturn(result);
}

value caml_kevent_byte(value *argv, int argc) {
  return caml_kevent(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

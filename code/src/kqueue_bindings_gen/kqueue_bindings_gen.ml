let c_headers = "#include <sys/types.h>\n#include <sys/event.h>\n#include <sys/time.h>"

let main () =
  let stubs_out = open_out "kqueue_bindings_stubs.c" in
  let stubs_fmt = Format.formatter_of_out_channel stubs_out in
  Format.fprintf stubs_fmt "%s@\n" c_headers;
  Cstubs_structs.write_c stubs_fmt (module Kqueue_bindings.Stubs);
  Format.pp_print_flush stubs_fmt ();
  close_out stubs_out

let () = main ()

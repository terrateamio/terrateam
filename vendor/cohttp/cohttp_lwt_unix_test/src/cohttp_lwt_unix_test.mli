include
  Cohttp_test.S
    with type 'a io = 'a Lwt.t
     and type body = Cohttp_lwt.Body.t
     and type ic = Lwt_io.input_channel
     and type oc = Lwt_io.output_channel

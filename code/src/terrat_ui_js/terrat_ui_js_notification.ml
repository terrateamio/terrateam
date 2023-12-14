module At = Brtl_js2.Brr.At

type t = {
  msg : Brtl_js2.Brr.El.t list;
  timestamp : Brtl_js2_datetime.t;
}

let make ?(timeout = Duration.of_sec 5) ~msg () =
  {
    msg;
    timestamp =
      Brtl_js2_datetime.(add_milliseconds (now ()) (float_of_int (Duration.to_ms timeout)));
  }

let msg t = t.msg
let timestamp t = t.timestamp

let msg_success msg =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "success") ]
        (span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "check_circle" ] :: msg);
    ]

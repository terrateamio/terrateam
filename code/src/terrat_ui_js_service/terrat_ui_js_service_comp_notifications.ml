module At = Brtl_js2.Brr.At

module Notice = struct
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
end

let make () = Brtl_js2.Note.E.create ()

let rec clear_dead_notifications notification_list set_notification_list =
  let open Abb_js.Future.Infix_monad in
  let now = Brtl_js2_datetime.(get_time (now ())) in
  let notifications = Brtl_js2.Note.S.value notification_list in
  set_notification_list
    (CCList.filter
       (fun n ->
         let timestamp = Notice.timestamp n in
         now < Brtl_js2_datetime.get_time timestamp)
       notifications);
  Abb_js.sleep 1.0 >>= fun () -> clear_dead_notifications notification_list set_notification_list

let run state =
  let open Abb_js.Future.Infix_monad in
  let notifications = Brtl_js2.State.app_state state in
  let notification_list, set_notification_list = Brtl_js2.Note.S.create ~eq:( = ) [] in
  let logr =
    Brtl_js2.Note.E.log notifications (fun n ->
        set_notification_list (Brtl_js2.Note.S.value notification_list @ [ n ]))
  in
  Abb_js.Future.fork (clear_dead_notifications notification_list set_notification_list)
  >>= fun clear_fut ->
  let rendered =
    Brtl_js2.Note.S.map
      ~eq:( = )
      (fun notifications ->
        CCList.map
          (fun n -> Brtl_js2.Brr.El.div ~at:At.[ class' (Jstr.v "notification") ] (Notice.msg n))
          notifications)
      notification_list
  in
  Abb_js.Future.return
    (Brtl_js2.Output.render
       ~cleanup:(fun () ->
         Brtl_js2.Note.Logr.destroy' logr;
         Abb_js.Future.abort clear_fut)
       rendered)

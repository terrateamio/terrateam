module Choice = struct
  type 'a t = {
    value : 'a;
    title : string;
    uri : Uri.t;
  }

  let create ~value ~title uri = { value; title; uri }
end

let run ~eq ~nav_class ~selected ~unselected ~choices routes state =
  let open Brtl_js.Html in
  Abb_js.Future.return
    (`With_cleanup
      ( [
          Brtl_js.Rhtml.div ~a:[ a_class [ nav_class ] ]
          @@ Brtl_js.Rlist.from_signal
          @@ Brtl_js.React.S.map
               (fun uri ->
                 let compare =
                   match Brtl_js_rtng.first_match routes uri with
                     | Some v -> eq (Brtl_js_rtng.Match.apply v)
                     | None   -> fun _ -> false
                 in
                 CCList.map
                   (fun choice ->
                     div
                       ~a:
                         [
                           a_class
                             [
                               ( if compare choice.Choice.value then
                                 selected
                               else
                                 unselected );
                             ];
                           a_onclick
                           @@ Brtl_js.handler_sync (fun _ ->
                                  Brtl_js.Router.navigate
                                    (Brtl_js.State.router state)
                                    choice.Choice.uri);
                         ]
                       [ txt choice.Choice.title ])
                   choices)
               (Brtl_js.Router.uri (Brtl_js.State.router state));
        ],
        fun _ -> Abb_js.Future.return () ))

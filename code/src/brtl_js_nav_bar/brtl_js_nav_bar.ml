module Title = struct
  type t =
    [ `Txt of string
    | `Html of unit -> Html_types.div_content Brtl_js.Html.elt list
    ]
end

module Choice = struct
  type 'a t = {
    value : 'a;
    title : Title.t;
    uri : Uri.t;
  }

  let create ~value ~title uri = { value; title; uri }
end

let run ~eq ~nav_class ~selected ~unselected ~choices routes state =
  let open Brtl_js.Html in
  let uri, set_uri =
    Brtl_js.React.S.(create ~eq:Uri.equal (value (Brtl_js.Router.uri (Brtl_js.State.router state))))
  in
  let workaround =
    Brtl_js.React.S.map (fun uri -> set_uri uri) (Brtl_js.Router.uri (Brtl_js.State.router state))
  in
  Abb_js.Future.return
    (`With_cleanup
      ( [
          Brtl_js.Rhtml.div ~a:[ a_class [ nav_class ] ]
          @@ Brtl_js.Rlist.from_signal
          @@ Brtl_js.React.S.map (fun mtch ->
                 let compare =
                   match mtch with
                   | Some v -> eq (Brtl_js_rtng.Match.apply v)
                   | None -> fun _ -> false
                 in
                 CCList.map
                   (fun choice ->
                     div
                       ~a:
                         [
                           a_class
                             [ (if compare choice.Choice.value then selected else unselected) ];
                           a_onclick
                           @@ Brtl_js.handler_sync (fun _ ->
                                  Brtl_js.Router.navigate
                                    (Brtl_js.State.router state)
                                    choice.Choice.uri);
                         ]
                       (match choice.Choice.title with
                       | `Txt title -> [ txt title ]
                       | `Html elt -> elt ()))
                   choices)
          @@ Brtl_js.React.S.map
               ~eq:(fun m1 m2 ->
                 match (m1, m2) with
                 | Some m1, Some m2 -> Brtl_js_rtng.Match.equal m1 m2
                 | None, None -> true
                 | _, _ -> false)
               (Brtl_js_rtng.first_match ~must_consume_path:false routes)
               uri;
        ],
        fun _ ->
          Brtl_js.React.S.stop ~strong:true workaround;
          Abb_js.Future.return () ))

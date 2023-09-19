module At = Brtl_js2.Brr.At

type page = string list

let page_equal = CCOption.equal (CCList.equal CCString.equal)

module type S = sig
  type elt
  type state

  val class' : string
  val page_param : string

  val fetch :
    ?page:page ->
    unit ->
    (elt Terrat_ui_js_client.Page.t, [> Terrat_ui_js_client.err ]) result Abb_js.Future.t

  val render_elt : state Brtl_js2.State.t -> elt -> Brtl_js2.Brr.El.t
  val equal : elt -> elt -> bool
end

module Make (S : S) = struct
  let rec refresh_page refresh_active set_refresh_active page set_res_page =
    let open Abb_js.Future.Infix_monad in
    Abb_js_future_combinators.with_finally
      (fun () ->
        set_refresh_active (Brtl_js2.Note.S.value refresh_active + 1);
        S.fetch ?page ())
      ~finally:(fun () ->
        set_refresh_active (Brtl_js2.Note.S.value refresh_active - 1);
        Abb_js.Future.return ())
    >>= function
    | Ok res_page ->
        set_res_page res_page;
        Abb_js.sleep 60.0
        >>= fun () -> refresh_page refresh_active set_refresh_active page set_res_page
    | Error err ->
        Abb_js.sleep 60.0
        >>= fun () ->
        Brtl_js2.Brr.Console.(
          log [ Jstr.v "Failed to load pull requests"; Jstr.v (Terrat_ui_js_client.show_err err) ]);
        refresh_page refresh_active set_refresh_active page set_res_page

  let run page state =
    let open Abb_js.Future.Infix_monad in
    let consumed_path = Brtl_js2.State.consumed_path state in
    let res_page, set_res_page =
      Brtl_js2.Note.S.create
        ~eq:(Terrat_ui_js_client.Page.equal S.equal)
        (Terrat_ui_js_client.Page.empty ())
    in
    let refresh_active, set_refresh_active = Brtl_js2.Note.S.create ~eq:( = ) 0 in
    let refresh_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~class':(Jstr.v "refresh")
        ~active:(Brtl_js2.Note.S.map ~eq:( = ) (fun v -> v > 0) refresh_active)
        ~action:(fun () ->
          Abb_js_future_combinators.with_finally
            (fun () ->
              set_refresh_active (Brtl_js2.Note.S.value refresh_active + 1);
              S.fetch ?page ()
              >>= function
              | Ok res_page ->
                  set_res_page res_page;
                  Abb_js.Future.return ()
              | Error err ->
                  Brtl_js2.Brr.Console.(
                    log
                      [
                        Jstr.v "Failed to load pull requests";
                        Jstr.v (Terrat_ui_js_client.show_err err);
                      ]);
                  Abb_js.Future.return ())
            ~finally:(fun () ->
              set_refresh_active (Brtl_js2.Note.S.value refresh_active - 1);
              Abb_js.Future.return ()))
        (Brtl_js2.Note.S.const
           ~eq:( == )
           Brtl_js2.Brr.El.
             [
               span
                 ~at:At.[ class' (Jstr.v "material-icons") ]
                 [ span ~at:At.[ class' (Jstr.v "text-2xl") ] [ txt' "refresh" ] ];
             ])
        ()
    in
    Abb_js.Future.fork (refresh_page refresh_active set_refresh_active page set_res_page)
    >>= fun refresh_fut ->
    let page =
      Brtl_js2.Note.S.map ~eq:(CCList.equal S.equal) Terrat_ui_js_client.Page.page res_page
    in
    let prev = Brtl_js2.Note.S.map ~eq:page_equal Terrat_ui_js_client.Page.prev res_page in
    let next = Brtl_js2.Note.S.map ~eq:page_equal Terrat_ui_js_client.Page.next res_page in
    let prev_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~enabled:(Brtl_js2.Note.S.map ~eq:CCBool.equal CCOption.is_some prev)
        ~action:(fun () ->
          match Brtl_js2.Note.S.value prev with
          | Some page ->
              Brtl_js2.Router.navigate
                (Brtl_js2.State.router state)
                (Uri.to_string
                   (Uri.add_query_param (Uri.of_string consumed_path) (S.page_param, page)));
              Abb_js.Future.return ()
          | None -> Abb_js.Future.return ())
        (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Prev" ])
        ()
    in
    let next_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~enabled:(Brtl_js2.Note.S.map ~eq:CCBool.equal CCOption.is_some next)
        ~action:(fun () ->
          match Brtl_js2.Note.S.value next with
          | Some page ->
              Brtl_js2.Router.navigate
                (Brtl_js2.State.router state)
                (Uri.to_string
                   (Uri.add_query_param (Uri.of_string consumed_path) (S.page_param, page)));
              Abb_js.Future.return ()
          | None -> Abb_js.Future.return ())
        (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Next" ])
        ()
    in
    let el = Brtl_js2.Brr.El.div ~at:At.[ class' (Jstr.v "page") ] [] in
    Brtl_js2.R.Elr.def_children
      el
      (Brtl_js2.Note.S.map ~eq:( == ) (fun elts -> CCList.map (S.render_elt state) elts) page);
    let page_el =
      Brtl_js2.R.Elr.with_rem
        (fun () -> Abb_js.Future.abort refresh_fut)
        Brtl_js2.Brr.El.(
          div
            ~at:At.[ class' (Jstr.v S.class') ]
            [
              div
                ~at:At.[ class' (Jstr.v "page-nav") ]
                [
                  div [ Brtl_js2.Kit.Ui.Button.el refresh_btn ];
                  div [ Brtl_js2.Kit.Ui.Button.el prev_btn ];
                  div [ Brtl_js2.Kit.Ui.Button.el next_btn ];
                ];
              el;
            ])
    in
    Abb_js.Future.return (Brtl_js2.Output.const [ page_el ])
end

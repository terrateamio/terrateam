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

  val wrap_page : Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list
  val render_elt : state Brtl_js2.State.t -> elt -> Brtl_js2.Brr.El.t list
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

  let page_comp refresh_active set_refresh_active res_page set_res_page page_ref page state =
    let open Abb_js.Future.Infix_monad in
    page_ref := page;
    Abb_js.Future.fork (refresh_page refresh_active set_refresh_active page set_res_page)
    >>= fun refresh_fut ->
    let page =
      Brtl_js2.Note.S.map ~eq:(CCList.equal S.equal) Terrat_ui_js_client.Page.page res_page
    in
    Abb_js.Future.return
      (Brtl_js2.Output.render
         ~cleanup:(fun () -> Abb_js.Future.abort refresh_fut)
         (Brtl_js2.Note.S.map
            ~eq:( == )
            (fun elts -> S.wrap_page (CCList.flat_map (S.render_elt state) elts))
            page))

  (* A standard pagination view.  The implementation might seem a little
     backwards: the inner page component is the one that gets the page from the
     URL and then elements outside of the page evaluate the results of the page.
     This is so that on page change, only the page view is redrawn.  Everything
     else is modified through signals from that component.  If the outer most
     component used the URL to get the page, the entire page component would
     be redrawn on every page change, which is not a pleasant UX. *)
  let run state =
    let open Abb_js.Future.Infix_monad in
    let consumed_path = Brtl_js2.State.consumed_path state in
    let res_page, set_res_page =
      Brtl_js2.Note.S.create
        ~eq:(Terrat_ui_js_client.Page.equal S.equal)
        (Terrat_ui_js_client.Page.empty ())
    in
    (* Don't know the page until the inner component is loaded, so make a ref
       that will be set when it is evaluated.  We need the page for the refresh
       button. *)
    let page_ref = ref None in
    let refresh_active, set_refresh_active = Brtl_js2.Note.S.create ~eq:( = ) 0 in
    let refresh_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~class':(Jstr.v "refresh")
        ~enabled:(Brtl_js2.Note.S.map ~eq:( = ) (fun v -> v = 0) refresh_active)
        ~action:(fun () ->
          Abb_js_future_combinators.with_finally
            (fun () ->
              set_refresh_active (Brtl_js2.Note.S.value refresh_active + 1);
              S.fetch ?page:!page_ref ()
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
        (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Refresh" ])
        ()
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
    let page_rt () =
      Brtl_js2_rtng.(root consumed_path /? Query.(option (array (string S.page_param))))
    in
    let page_el =
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
            Brtl_js2.Router_output.create
              state
              el
              Brtl_js2_rtng.
                [
                  page_rt ()
                  --> page_comp refresh_active set_refresh_active res_page set_res_page page_ref;
                ];
          ])
    in
    Abb_js.Future.return (Brtl_js2.Output.const [ page_el ])
end

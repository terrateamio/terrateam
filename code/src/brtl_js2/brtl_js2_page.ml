module At = Brtl_js2.Brr.At

module Page = struct
  type 'a t = {
    elts : 'a list;
    next : string list option;
    prev : string list option;
  }
  [@@deriving eq, show]

  let make ?next ?prev elts = { elts; next; prev }
  let page t = t.elts
  let next t = t.next
  let prev t = t.prev
end

type page = string list [@@deriving eq]

module Query = struct
  type 'a t = {
    query : 'a Brtl_js2.Note.signal;
    set_query : 'a Brtl_js2.Note.S.set;
  }

  let query t = Brtl_js2.Note.S.value t.query
  let signal t = t.query
  let set_query t v = t.set_query v
end

module type S = sig
  type fetch_err
  type elt [@@deriving eq, show]
  type state
  type query

  val class' : string
  val query : query Brtl_js2_rtng.Route.t
  val make_uri : query -> Uri.t -> Uri.t
  val set_page : string list option -> query -> query
  val fetch : query -> (elt Page.t, fetch_err) result Abb_js.Future.t
  val wrap_page : query Query.t -> Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list
  val render_elt : state Brtl_js2.State.t -> query Query.t -> elt -> Brtl_js2.Brr.El.t list

  val query_comp :
    (query Brtl_js2.Note.S.set -> fetch_err option Brtl_js2.Note.E.t -> state Brtl_js2.Comp.t)
    option

  val equal_elt : elt -> elt -> bool
  val equal_query : query -> query -> bool
  val pp_fetch_err : Ppx_deriving_runtime.Format.formatter -> fetch_err -> Ppx_deriving_runtime.unit
  val show_fetch_err : fetch_err -> Ppx_deriving_runtime.string
end

module Make (S : S) = struct
  let perform_fetch set_refresh_active refresh_active set_res_page send_fetch_err query =
    let open Abb_js.Future.Infix_monad in
    Abb_js_future_combinators.with_finally
      (fun () ->
        set_refresh_active (Brtl_js2.Note.S.value refresh_active + 1);
        S.fetch query
        >>= function
        | Ok res_page ->
            set_res_page res_page;
            send_fetch_err None;
            Abb_js.Future.return ()
        | Error err ->
            Brtl_js2.Brr.Console.(
              log [ Jstr.v "Failed to load pull requests"; Jstr.v (S.show_fetch_err err) ]);
            send_fetch_err (Some err);
            Abb_js.Future.return ())
      ~finally:(fun () ->
        set_refresh_active (Brtl_js2.Note.S.value refresh_active - 1);
        Abb_js.Future.return ())

  let rec refresh_page set_refresh_active refresh_active set_res_page send_fetch_err query =
    let open Abb_js.Future.Infix_monad in
    perform_fetch set_refresh_active refresh_active set_res_page send_fetch_err (Query.query query)
    >>= fun () ->
    Abb_js.sleep 60.0
    >>= fun () -> refresh_page set_refresh_active refresh_active set_res_page send_fetch_err query

  let page_comp query res_page state =
    let page = Brtl_js2.Note.S.map ~eq:(CCList.equal S.equal_elt) Page.page res_page in
    Abb_js.Future.return
      (Brtl_js2.Output.render
         (Brtl_js2.Note.S.map
            ~eq:( == )
            (fun elts -> S.wrap_page query (CCList.flat_map (S.render_elt state query) elts))
            page))

  let run state =
    let open Abb_js.Future.Infix_monad in
    let uri = Brtl_js2.(Note.S.value (Router.uri (State.router state))) in
    let query =
      CCOption.get_exn_or
        "query"
        (CCOption.map Brtl_js2_rtng.Match.apply (Brtl_js2_rtng.match_uri S.query uri))
    in
    let query, set_query = Brtl_js2.Note.S.create ~eq:S.equal_query query in
    let query = { Query.query; set_query } in
    let fetch_err, send_fetch_err = Brtl_js2.Note.E.create () in
    let res_page, set_res_page =
      Brtl_js2.Note.S.create ~eq:(Page.equal S.equal_elt) (Page.make [])
    in
    let refresh_active, set_refresh_active = Brtl_js2.Note.S.create ~eq:( = ) 0 in
    Abb_js.Future.fork
      (refresh_page set_refresh_active refresh_active set_res_page send_fetch_err query)
    >>= fun refresh_fut ->
    let logr =
      Brtl_js2.Note.S.log ~now:false (Query.signal query) (fun query ->
          let uri = Brtl_js2.(Note.S.value (Router.uri (State.router state))) in
          Brtl_js2.Router.navigate
            (Brtl_js2.State.router state)
            (Uri.to_string (S.make_uri query uri));
          Abb_js.Future.run
            (perform_fetch set_refresh_active refresh_active set_res_page send_fetch_err query))
    in
    let refresh_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~class':(Jstr.v "refresh")
        ~enabled:(Brtl_js2.Note.S.map ~eq:( = ) (fun v -> v = 0) refresh_active)
        ~action:(fun () ->
          perform_fetch
            set_refresh_active
            refresh_active
            set_res_page
            send_fetch_err
            (Query.query query))
        (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Refresh" ])
        ()
    in
    let prev = Brtl_js2.Note.S.map ~eq:(CCOption.equal equal_page) Page.prev res_page in
    let next = Brtl_js2.Note.S.map ~eq:(CCOption.equal equal_page) Page.next res_page in
    let prev_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~enabled:(Brtl_js2.Note.S.map ~eq:CCBool.equal CCOption.is_some prev)
        ~action:(fun () ->
          Query.set_query query (S.set_page (Brtl_js2.Note.S.value prev) (Query.query query));
          Abb_js.Future.return ())
        (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Prev" ])
        ()
    in
    let next_btn =
      Brtl_js2.Kit.Ui.Button.v'
        ~enabled:(Brtl_js2.Note.S.map ~eq:CCBool.equal CCOption.is_some next)
        ~action:(fun () ->
          set_query (S.set_page (Brtl_js2.Note.S.value next) (Query.query query));
          Abb_js.Future.return ())
        (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Next" ])
        ()
    in
    let el = Brtl_js2.Brr.El.div ~at:At.[ class' (Jstr.v "page") ] [] in
    let page_el =
      Brtl_js2.Brr.El.(
        div
          ~at:At.[ class' (Jstr.v S.class') ]
          (CCList.flatten
             [
               (match S.query_comp with
               | Some comp ->
                   [
                     Brtl_js2.Router_output.const
                       state
                       (div ~at:At.[ class' (Jstr.v "query") ] [])
                       (comp set_query fetch_err);
                   ]
               | None -> []);
               [
                 div
                   ~at:At.[ class' (Jstr.v "page-nav") ]
                   [
                     div [ Brtl_js2.Kit.Ui.Button.el refresh_btn ];
                     div [ Brtl_js2.Kit.Ui.Button.el prev_btn ];
                     div [ Brtl_js2.Kit.Ui.Button.el next_btn ];
                   ];
                 Brtl_js2.Router_output.const state el (page_comp query res_page);
               ];
             ]))
    in
    Abb_js.Future.return
      (Brtl_js2.Output.const
         ~cleanup:(fun () ->
           Brtl_js2.Note.Logr.destroy logr;
           Abb_js.Future.abort refresh_fut)
         [ page_el ])
end

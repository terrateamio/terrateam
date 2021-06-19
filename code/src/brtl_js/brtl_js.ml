open Js_of_ocaml
module React = React
module Rhtml = Js_of_ocaml_tyxml.Tyxml_js.R.Html
module Rsvg = Js_of_ocaml_tyxml.Tyxml_js.R.Svg
module Rlist = ReactiveData.RList
module Html = Js_of_ocaml_tyxml.Tyxml_js.Html
module Svg = Js_of_ocaml_tyxml.Tyxml_js.Svg
module To_dom = Js_of_ocaml_tyxml.Tyxml_js.To_dom

let select_by_id id coerce = Option.get (Dom_html.getElementById_coerce id coerce)

let select_by_id_opt id coerce = Dom_html.getElementById_coerce id coerce

module Router = struct
  type t = {
    uri : Uri.t React.signal;
    uri_set : ?step:React.step -> Uri.t -> unit;
  }

  let on_pop_state uri_set _ =
    let current_uri = Dom_html.window##.location##.href |> Js.to_string |> Uri.of_string in
    uri_set current_uri;
    Js._true

  let create () =
    let current_uri = Dom_html.window##.location##.href |> Js.to_string |> Uri.of_string in
    let (uri, uri_set) = React.S.create current_uri in
    Dom_html.window##.onpopstate := Dom_html.handler (on_pop_state uri_set);
    { uri; uri_set }

  let uri t = t.uri

  let navigate t uri =
    Dom_html.window##.history##pushState
      Js.null
      (Js.string "")
      (Js.some (Js.string (Uri.to_string uri)));
    t.uri_set uri
end

module State = struct
  type t = {
    router : Router.t;
    mutable consumed_path : string;
    (* TODO: Make consumed_path immutable *)
    cleanup : (string, t -> unit Abb_js.Future.t) Hashtbl.t;
  }

  let rec iter_nodes t node =
    Js.Opt.iter (Dom_html.CoerceTo.element node) (fun node ->
        (match Js.Opt.to_option (node##getAttribute (Js.string "id")) with
          | Some id -> (
              let id = Js.to_string id in
              match Hashtbl.find_opt t.cleanup id with
                | Some f ->
                    Hashtbl.remove t.cleanup id;
                    (* TODO: Should all these run in parallel? *)
                    Abb_js.Future.run (f t)
                | None   -> ())
          | None    -> ());
        for i = 0 to node##.childNodes##.length do
          Js.Opt.iter (node##.childNodes##item i) (iter_nodes t)
        done)

  let mutation_observer t (records : MutationObserver.mutationRecord Js.t Js.js_array Js.t) _ =
    let records = Js.to_array records in
    CCArray.iter
      (fun record ->
        let nodes = record##.removedNodes in
        for i = 0 to nodes##.length do
          Js.Opt.iter (nodes##item i) (iter_nodes t)
        done)
      records

  let create id =
    let t = { router = Router.create (); consumed_path = ""; cleanup = Hashtbl.create 10 } in
    let id_div = select_by_id id Dom_html.CoerceTo.div in
    ignore
      (MutationObserver.observe
         ~node:id_div
         ~f:(mutation_observer t)
         ~child_list:true
         ~subtree:true
         ());
    t

  let router t = t.router

  let consumed_path t = t.consumed_path

  let cleanup t id f = Hashtbl.replace t.cleanup id f
end

module Handler = struct
  type ret =
    [ `Render       of Html_types.div_content_fun Html.elt list
    | `With_cleanup of Html_types.div_content_fun Html.elt list * (State.t -> unit Abb_js.Future.t)
    | `Navigate     of Uri.t
    ]

  type t = State.t -> ret Abb_js.Future.t
end

module Router_output = struct
  let match_uri routes uri = Brtl_js_rtng.first_match ~must_consume_path:false routes uri

  let apply_match mtch state with_cleanup res_set =
    Abb_js.Future.run
      (state.State.consumed_path <- Brtl_js_rtng.Match.consumed_path mtch;
       Abb_js.Future.await_bind
         (function
           | `Det (`Render r)                  -> (
               res_set r;
               match !with_cleanup with
                 | Some f ->
                     with_cleanup := None;
                     f state
                 | None   -> Abb_js.Future.return ())
           | `Det (`With_cleanup (r, cleanup)) -> (
               res_set r;
               match !with_cleanup with
                 | Some f ->
                     with_cleanup := Some cleanup;
                     f state
                 | None   ->
                     with_cleanup := Some cleanup;
                     Abb_js.Future.return ())
           | `Det (`Navigate uri)              ->
               Router.navigate (State.router state) uri;
               Abb_js.Future.return ()
           | `Aborted                          ->
               res_set [];
               Abb_js.Future.return ()
           | `Exn exn                          ->
               Firebug.console##log_2 (Js.string "Unhandled exn") exn;
               res_set [];
               Abb_js.Future.return ())
         (Brtl_js_rtng.Match.apply mtch state))

  let route_uri state routes with_cleanup prev_match res_set uri =
    let match_opt = match_uri routes uri in
    match match_opt with
      | Some mtch when not (Brtl_js_rtng.Match.equal mtch !prev_match) ->
          prev_match := mtch;
          apply_match mtch state with_cleanup res_set
      | Some mtch ->
          (* TODO: make consumed path immutable.

             If the matched route didn't change, just update the consumed
             path. *)
          state.State.consumed_path <- Brtl_js_rtng.Match.consumed_path mtch
      | None -> (
          (* This router doesn't match, so cleanup *)
          match !with_cleanup with
            | Some f ->
                with_cleanup := None;
                Abb_js.Future.run (f state)
            | None   -> ())

  let create ?(a = []) state routes =
    (* TODO: Consumed path immutable *)
    let state = State.{ state with consumed_path = "" } in
    let uri = state |> State.router |> Router.uri in
    let (res, res_set) = React.S.create [] in
    (* Perform initial routing *)
    let mtch =
      match match_uri routes (React.S.value uri) with
        | Some mtch -> mtch
        | None      ->
            (* TODO: Do something useful here *)
            assert false
    in
    let with_cleanup = ref None in
    let prev_match = ref mtch in
    let id = Uuidm.to_string (Uuidm.create `V4) in
    let iter =
      React.S.fmap
        (fun uri ->
          route_uri state routes with_cleanup prev_match res_set uri;
          None)
        []
        uri
    in
    let v = Rlist.from_signal res in
    (* This needs to happen after creating [v] because events are transient so
       we need to create the plumbing and then set the first value of routing,
       otherwise we'll get the default value given to [hold], which is the empty
       list. *)
    apply_match mtch state with_cleanup res_set;
    let cleanup state =
      React.S.stop ~strong:true iter;
      React.S.stop ~strong:true res;
      match !with_cleanup with
        | Some f -> f state
        | None   -> Abb_js.Future.return ()
    in
    State.cleanup state id cleanup;
    Rhtml.div ~a:(Html.a_id id :: a) v
end

let comp ?(a = []) state handler =
  let id = Uuidm.to_string (Uuidm.create `V4) in
  let (ret, handle) = Rlist.create [] in
  try
    Abb_js.Future.run
      (let open Abb_js.Future.Infix_monad in
      handler state
      >>| function
      | `Render r            -> Rlist.set handle r
      | `With_cleanup (r, f) ->
          Rlist.set handle r;
          State.cleanup state id f
      | `Navigate uri        -> Router.navigate (State.router state) uri);
    Rhtml.div ~a:(Html.a_id id :: a) ret
  with exn ->
    Js_of_ocaml.(Firebug.console##log_2 (Js.string "Component failure") exn);
    assert false

let dom_html_handler ?(continue = false) f =
  let wrapper event =
    Abb_js.Future.run (f event);
    Js.bool continue
  in
  Dom_html.handler wrapper

let handler ?(continue = false) f event =
  Abb_js.Future.run (f event);
  continue

let handler_sync ?(continue = false) f event =
  f event;
  continue

let scroll_into_view ?(block = "start") ?(inline = "nearest") (elem : Dom_html.element Js.t) =
  let behaviour =
    object%js
      val behavior = Js.string "smooth"

      val block = Js.string block

      val inline = Js.string inline
    end
  in
  ignore (Js.Unsafe.meth_call elem "scrollIntoView" [| Js.Unsafe.inject behaviour |])

let replace_child ?p ~old n =
  match p with
    | None   -> Js.Opt.iter old##.parentNode (fun p -> Dom.replaceChild p n old)
    | Some p -> Dom.replaceChild p n old

let append_child ~p n = Dom.appendChild p n

let remove_child ~p r = Dom.removeChild p r

let filter_attrib = Js_of_ocaml_tyxml.Tyxml_js.R.filter_attrib

let main id f =
  let wrapper _ =
    let id_div = select_by_id id Dom_html.CoerceTo.div in
    let state = State.create id in
    f state id_div
  in
  Dom_html.window##.onload := dom_html_handler wrapper

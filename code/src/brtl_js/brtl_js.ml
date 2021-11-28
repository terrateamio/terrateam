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
    let (uri, uri_set) = React.S.create ~eq:Uri.equal current_uri in
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
    visibility : [ `Visible | `Hidden | `Unknown of string ] React.signal;
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

  let create id visibility =
    let t =
      { router = Router.create (); consumed_path = ""; cleanup = Hashtbl.create 10; visibility }
    in
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

  let app_visibility t = t.visibility
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

  let apply_match mtch iteration curr_iteration state with_cleanup res_set =
    Abb_js.Future.run
      (state.State.consumed_path <- Brtl_js_rtng.Match.consumed_path mtch;
       Abb_js.Future.await_bind
         (function
           | `Det (`Render r) when iteration = !curr_iteration -> (
               res_set r;
               match !with_cleanup with
                 | Some f ->
                     with_cleanup := None;
                     f state
                 | None   -> Abb_js.Future.return ())
           | `Det (`With_cleanup (r, cleanup)) when iteration = !curr_iteration -> (
               res_set r;
               match !with_cleanup with
                 | Some f ->
                     with_cleanup := Some cleanup;
                     f state
                 | None   ->
                     with_cleanup := Some cleanup;
                     Abb_js.Future.return ())
           | `Det (`With_cleanup (_, cleanup)) ->
               (* If the iterations do not match, ensure we perform the cleanup  *)
               Firebug.console##log_3
                 (Js.string "Not updating due to iteration mismatch, cleaning up")
                 iteration
                 !curr_iteration;
               cleanup state
           | `Det (`Navigate uri) when iteration = !curr_iteration ->
               Router.navigate (State.router state) uri;
               Abb_js.Future.return ()
           | `Aborted when iteration = !curr_iteration ->
               res_set [];
               Abb_js.Future.return ()
           | `Exn exn when iteration = !curr_iteration ->
               Firebug.console##log_2 (Js.string "Unhandled exn") exn;
               res_set [];
               Abb_js.Future.return ()
           | _ ->
               Firebug.console##log_3
                 (Js.string "Not updating due to iteration mismatch")
                 iteration
                 !curr_iteration;
               Abb_js.Future.return ())
         (Brtl_js_rtng.Match.apply mtch state))

  let route_uri iteration state routes with_cleanup prev_match res_set uri =
    let match_opt = match_uri routes uri in
    (* Check the URL match.  If the match does not match the previous one but
       there still is a match then increment the iteration and apply that match.
       If we don't match anything then also increment the iteration and clean
       up.  We increment the iteration when a match changes so any renders that
       could be running will know to perform a cleanup (if there is anything to
       clean up). *)
    match match_opt with
      | Some mtch when not (Brtl_js_rtng.Match.equal mtch !prev_match) ->
          prev_match := mtch;
          incr iteration;
          apply_match mtch !iteration iteration state with_cleanup res_set
      | Some mtch ->
          (* TODO: make consumed path immutable.

             If the matched route didn't change, just update the consumed
             path. *)
          state.State.consumed_path <- Brtl_js_rtng.Match.consumed_path mtch
      | None -> (
          incr iteration;
          (* This router doesn't match, so cleanup *)
          match !with_cleanup with
            | Some f ->
                with_cleanup := None;
                Abb_js.Future.run (f state)
            | None   -> ())

  let create ?(a = []) state routes =
    (* TODO: Consumed path immutable *)
    (* Rendering a page can take an unbounded amount of time and in that time a
       user may choose to navigate to a different page.  To ensure the latest
       page is the one that gets rendered, we track iterations and only assign
       the results in the case of the iteration being rendering being the
       current iteration.  For example, a user has navigated to page P1 which
       takes 2 seconds to render and in that time they navigate to P2 which
       takes 1 second to render.  P2 would be rendered at 1 second and then at 2
       seconds P1 would finish rendering and replace the contents of P2
       (assuming the component it applies to still exists on the page).  But by
       tracking iterations, P1's iteration would be 1 and P2's iteration would
       be 2.  Once P2 starts it the current iteration would be 2 because there
       have been two navigations.  When P2 goes to render, it would see that the
       current iteration is 2 and its iteration is 2, therefore it can set the
       results of its render.  When P1 finishes, it would see that its iteration
       is 1 and the current iteration is 2, therefore it cannot set its results.

       There is a similar issue when rendering a page kicks off things that need
       to be cleaned up.  For example if there is a recurring background task to
       update some element of the page, we will know the clean up that task
       because the iteration it was created on does not match the current
       iteration.

       There are a few things to note in this implementation.

       The first is that this allows unnecessary work to be executed.  Because
       we do not stop P1 from rendering when we know they are navigating away
       from it, P1 will still run to completion.  This is chosen because it's
       easy to think about and it becomes painfully hard to implement a renderer
       that can be aborted at any point.  Cleaning up work becomes hard to think
       about.

       This means the UI can be confusing to a user.  For example, a loading
       indicator can be active despite P2 not loading any data.

       It also means that when P1 finishes, we do need to perform its cleanup
       operation even though we won't be rendering it.

       With all this, a user of Brtl_js should strive to make rendering happen
       as quickly as possible, use [Abb_js.fork] to background any long running
       work and aborting that work in with a [`With_cleanup]. *)
    let iteration = ref 0 in
    let state = State.{ state with consumed_path = "" } in
    let uri = state |> State.router |> Router.uri in
    let (res, res_set) = React.S.create [] in
    (* Perform initial routing *)
    match match_uri routes (React.S.value uri) with
      | Some mtch ->
          let with_cleanup = ref None in
          let prev_match = ref mtch in
          let id = Uuidm.to_string (Uuidm.create `V4) in
          let iter =
            React.S.fmap
              (fun uri ->
                route_uri iteration state routes with_cleanup prev_match res_set uri;
                None)
              []
              uri
          in
          let v = Rlist.from_signal res in
          apply_match mtch 0 iteration state with_cleanup res_set;
          let cleanup state =
            React.S.stop ~strong:true iter;
            React.S.stop ~strong:true res;
            match !with_cleanup with
              | Some f -> f state
              | None   -> Abb_js.Future.return ()
          in
          State.cleanup state id cleanup;
          Rhtml.div ~a:(Html.a_id id :: a) v
      | None      ->
          (* TODO: Do something useful here.  Here we give an empty div.  Perhaps
             should give a div that can change if the URL eventually matches.  But
             perhaps its better to just do this and a user of [Router_output]
             should always match every URL that is valid on that page. *)
          Firebug.console##log (Js.string "URL does not match any route");
          Html.div []
end

let comp ?a state handler =
  (* A component is implemented just as a router output with one route.  There
     are a bunch of edge cases around navigating while rendering that router
     output takes care of. *)
  let consumed_path = State.consumed_path state in
  let curr_location () = Brtl_js_rtng.(root consumed_path) in
  Router_output.create ?a state Brtl_js_rtng.[ curr_location () --> handler ]

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

let tri_merge base ~on_true ~on_false signal =
  React.S.map
    (function
      | true  -> base @ on_true
      | false -> base @ on_false)
    signal

let merge ?(flip = false) steady optional signal =
  tri_merge
    steady
    ~on_true:
      (if not flip then
        optional
      else
        [])
    ~on_false:
      (if not flip then
        []
      else
        optional)
    signal

let main id f =
  let wrapper _ =
    let id_div = select_by_id id Dom_html.CoerceTo.div in
    let visibility_change_event = Dom.Event.make "visibilitychange" in
    let (visibility, set_visibility) = React.S.create `Visible in
    ignore
      (Dom_html.addEventListener
         Dom_html.document
         visibility_change_event
         (dom_html_handler (fun _ ->
              let visibility_state : Js.js_string Js.t Js.optdef =
                Js.Unsafe.js_expr "document.visibilityState"
              in
              Js.Optdef.iter visibility_state (fun s ->
                  match Js.to_string s with
                    | "visible" -> set_visibility `Visible
                    | "hidden"  -> set_visibility `Hidden
                    | s         -> set_visibility (`Unknown s));
              Abb_js.Future.return ()))
         Js._true);
    let state = State.create id visibility in
    f state id_div
  in
  Dom_html.window##.onload := dom_html_handler wrapper

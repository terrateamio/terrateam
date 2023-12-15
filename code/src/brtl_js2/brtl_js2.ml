module Note = struct
  type 'a signal = 'a Note.signal
  type 'a event = 'a Note.event

  module Step = Note.Step

  module Logr = struct
    include Note.Logr

    let destroy' = function
      | Some logr -> destroy logr
      | None -> ()
  end

  module S = struct
    include Note.S

    let create ~eq v = Note.S.create ~eq v
    let const ~eq v = Note.S.const ~eq v
    let hold ~eq v e = Note.S.hold ~eq v e
    let map ~eq f t = Note.S.map ~eq f t
    let app ~eq f s = Note.S.app ~eq f s
    let accum ~eq v f = Note.S.accum ~eq v f
    let fix ~eq v f = Note.S.fix ~eq v f
    let l1 ~eq f t = Note.S.l1 ~eq f t
    let l2 ~eq f t1 t2 = Note.S.l2 ~eq f t1 t2
    let l3 ~eq f t1 t2 t3 = Note.S.l3 ~eq f t1 t2 t3
  end

  module E = Note.E
end

module Brr = Brr

module R = struct
  include Note_brr

  module Elr = struct
    include Note_brr.Elr

    let on_add f el = Note_brr.Elr.on_add (fun () -> Abb_js.Future.run (f ())) el
    let on_rem f el = Note_brr.Elr.on_rem (fun () -> Abb_js.Future.run (f ())) el

    let with_add f el =
      on_add f el;
      el

    let with_rem f el =
      on_rem f el;
      el
  end
end

module Kit = struct
  include Note_brr_kit

  module Ui = struct
    include Note_brr_kit.Ui

    module Value_selector = struct
      include Note_brr_kit.Ui.Value_selector

      module Menu = struct
        include Note_brr_kit.Ui.Value_selector.Menu

        let v' ?class' ?enabled ~action:action' label choices sel =
          let menu = v ?class' ?enabled label choices sel in
          match Note.E.log (action menu) (fun v -> Abb_js.Future.run (action' v)) with
          | Some logr ->
              R.Elr.on_rem
                (fun () ->
                  Note.Logr.destroy logr;
                  Abb_js.Future.return ())
                (el menu);
              menu
          | None -> failwith "menu logr"
      end
    end

    module Button = struct
      include Note_brr_kit.Ui.Button

      let v' ?class' ?active ?enabled ?tip ~action:action' els value =
        let btn = v ?class' ?active ?enabled ?tip els value in
        match Note.E.log (action btn) (fun v -> Abb_js.Future.run (action' v)) with
        | Some logr ->
            R.Elr.on_rem
              (fun () ->
                Note.Logr.destroy logr;
                Abb_js.Future.return ())
              (el btn);
            btn
        | None -> failwith "button logr"
    end
  end
end

module Brr_fut = struct
  let fut_of_brr_fut fut =
    let p = Abb_fut_js.Promise.create () in
    Fut.await fut (fun v -> Abb_fut_js.run (Abb_fut_js.Promise.set p v));
    Abb_fut_js.Promise.future p

  let brr_fut_of_fut fut =
    let open Abb_fut_js.Infix_monad in
    let brr_fut, set = Fut.create () in
    Abb_fut_js.fork (fut >>| set) >>= fun _ -> Abb_fut_js.return brr_fut
end

module Router = struct
  type t = {
    uri : Uri.t Note.S.t;
    uri_set : Uri.t Note.S.set;
  }

  let create () =
    let current_uri =
      Brr.G.window |> Brr.Window.location |> Brr.Uri.to_jstr |> Jstr.to_string |> Uri.of_string
    in
    let uri, uri_set = Note.S.create ~eq:Uri.equal current_uri in
    ignore
      (Brr.Ev.listen
         Brr.Window.History.Ev.popstate
         (fun _ ->
           let current_uri =
             Brr.G.window
             |> Brr.Window.location
             |> Brr.Uri.to_jstr
             |> Jstr.to_string
             |> Uri.of_string
           in
           uri_set current_uri)
         (Brr.Window.as_target Brr.G.window));
    { uri; uri_set }

  let uri t = t.uri

  let navigate ?base t path =
    let base =
      match base with
      | Some base -> base
      | None -> Brr.G.window |> Brr.Window.location |> Brr.Uri.to_jstr |> Jstr.to_string
    in
    let uri' =
      match Brr.Uri.of_jstr ~base:(Jstr.v base) (Jstr.v path) with
      | Ok t -> t
      | Error err ->
          Brr.Console.(log [ Jstr.v "Exn"; Jstr.v "Router.navigate"; err ]);
          assert false
    in
    Brr.Window.History.push_state ~uri:uri' (Brr.Window.history Brr.G.window);
    t.uri_set (uri' |> Brr.Uri.to_jstr |> Jstr.to_string |> Uri.of_string)
end

module State = struct
  module Visibility = struct
    type t =
      [ `Visible
      | `Hidden
      ]
    [@@deriving eq]
  end

  type 'a t = {
    router : Router.t;
    consumed_path : string;
    visibility : Visibility.t Note.S.t;
    app_state : 'a;
  }

  let create app_state =
    let visibility =
      if
        Jstr.equal
          (Brr.Document.visibility_state Brr.G.document)
          Brr.Document.Visibility_state.visible
      then `Visible
      else `Hidden
    in
    let visibility, set_visibility = Note.S.create ~eq:Visibility.equal visibility in
    ignore
      (Brr.Ev.listen
         Brr.Ev.visibilitychange
         (fun _ ->
           set_visibility
             (if
                Jstr.equal
                  (Brr.Document.visibility_state Brr.G.document)
                  Brr.Document.Visibility_state.visible
              then `Visible
              else `Hidden))
         (Brr.Document.as_target Brr.G.document));
    { router = Router.create (); consumed_path = ""; visibility; app_state }

  let router t = t.router
  let consumed_path t = t.consumed_path
  let app_visibility t = t.visibility
  let app_state t = t.app_state
  let with_app_state app_state t = { t with app_state }
end

module Output = struct
  type t =
    | Render of {
        cleanup : unit -> unit Abb_js.Future.t;
        els : Brr.El.t list Note.S.t;
      }
    | Redirect of string
    | Navigate of Brr.Uri.t

  let render ?(cleanup = fun () -> Abb_js.Future.return ()) els = Render { cleanup; els }
  let const ?cleanup els = render ?cleanup (Note.S.const ~eq:( == ) els)
  let redirect path = Redirect path

  let navigate uri =
    match Brr.Uri.of_jstr (Jstr.v (Uri.to_string uri)) with
    | Ok uri -> Navigate uri
    | Error err ->
        Brr.Console.(
          log [ Jstr.v "Exn"; Jstr.v "Output.navigate"; Jstr.v (Uri.to_string uri); err ]);
        assert false
end

module Comp = struct
  type 'a t = 'a State.t -> Output.t Abb_js.Future.t
end

module Router_output = struct
  let match_uri routes uri = Brtl_js2_rtng.first_match ~must_consume_path:false routes uri

  let apply_match mtch iteration curr_iteration state with_cleanup el =
    Abb_js.Future.run
      (let state = { state with State.consumed_path = Brtl_js2_rtng.Match.consumed_path mtch } in
       Abb_js.Future.await_bind
         (function
           | `Det Output.(Render { cleanup; els }) when iteration = !curr_iteration ->
               let open Abb_js.Future.Infix_monad in
               !with_cleanup ()
               >>= fun () ->
               let logr = Note.S.log els (Brr.El.set_children el) in
               (with_cleanup :=
                  fun () ->
                    Note.Logr.destroy logr;
                    cleanup ());
               Abb_js.Future.return ()
           | `Det (Output.Redirect path) when iteration = !curr_iteration ->
               let open Abb_js.Future.Infix_monad in
               !with_cleanup ()
               >>= fun () ->
               (with_cleanup := fun () -> Abb_js.Future.return ());
               Router.navigate (State.router state) path;
               Abb_js.Future.return ()
           | `Det (Output.Navigate uri) when iteration = !curr_iteration ->
               let open Abb_js.Future.Infix_monad in
               !with_cleanup ()
               >>= fun () ->
               (with_cleanup := fun () -> Abb_js.Future.return ());
               Brr.Window.set_location Brr.G.window uri;
               Abb_js.Future.return ()
           | `Aborted when iteration = !curr_iteration ->
               let open Abb_js.Future.Infix_monad in
               !with_cleanup ()
               >>= fun () ->
               (with_cleanup := fun () -> Abb_js.Future.return ());
               Brr.El.set_children el [];
               Abb_js.Future.return ()
           | `Exn exn when iteration = !curr_iteration ->
               let open Abb_js.Future.Infix_monad in
               !with_cleanup ()
               >>= fun () ->
               (with_cleanup := fun () -> Abb_js.Future.return ());
               Brr.Console.(log [ Jstr.of_string "Unhandled exn"; exn ]);
               Brr.El.set_children el [];
               Abb_js.Future.return ()
           | _ ->
               Brr.Console.(
                 log
                   [
                     Jstr.of_string "Not updating due to iteration mismatch";
                     iteration;
                     !curr_iteration;
                   ]);
               Abb_js.Future.return ())
         (try Brtl_js2_rtng.Match.apply mtch state
          with exn ->
            Brr.Console.(log [ Jstr.of_string "EXN"; exn ]);
            Brr.El.set_children el [];
            assert false))

  let route_uri iteration state routes prev_match with_cleanup consumed_path el uri =
    let match_opt = match_uri routes uri in
    (* Check the URL match.  If the match does not match the previous one but
       there still is a match then increment the iteration and apply that match.
       If we don't match anything then also increment the iteration and clean
       up.  We increment the iteration when a match changes so any renders that
       could be running will know to perform a cleanup (if there is anything to
       clean up). *)
    match match_opt with
    | Some mtch when not (Brtl_js2_rtng.Match.equal mtch !prev_match) ->
        prev_match := mtch;
        consumed_path := Brtl_js2_rtng.Match.consumed_path mtch;
        incr iteration;
        apply_match mtch !iteration iteration state with_cleanup el
    | Some _ ->
        (* Match didn't change, so do nothing *)
        ()
    | None -> incr iteration

  let create state el routes =
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
    let uri = state |> State.router |> Router.uri in
    (* Perform initial routing *)
    match match_uri routes (Note.S.value uri) with
    | Some mtch ->
        let consumed_path = ref (Brtl_js2_rtng.Match.consumed_path mtch) in
        let with_cleanup = ref (fun () -> Abb_js.Future.return ()) in
        let prev_match = ref mtch in
        let uri_logr =
          Note.S.log uri (fun uri ->
              route_uri iteration state routes prev_match with_cleanup consumed_path el uri)
        in
        R.Elr.on_rem
          (fun () ->
            Note.Logr.destroy uri_logr;
            !with_cleanup ())
          el;
        apply_match mtch !iteration iteration state with_cleanup el;
        el
    | None ->
        (* TODO: Do something useful here.  Here we give an empty div.  Perhaps
           should give a div that can change if the URL eventually matches.  But
           perhaps its better to just do this and a user of [Router_output]
           should always match every URL that is valid on that page. *)
        Brr.Console.(log [ Jstr.of_string "URL does not match any route" ]);
        el

  let const state el comp =
    let consumed_path = State.consumed_path state in
    let r () = Brtl_js2_rtng.(root consumed_path) in
    create state el Brtl_js2_rtng.[ r () --> comp ]
end

module Ph = struct
  let handle_output cleanup_ref set_els state = function
    | Output.(Render { cleanup; els }) ->
        let logr = Note.S.log els set_els in
        (cleanup_ref :=
           fun () ->
             Note.Logr.destroy logr;
             cleanup ());
        Abb_js.Future.return ()
    | Output.Redirect path ->
        Router.navigate (State.router state) path;
        Abb_js.Future.return ()
    | Output.Navigate uri ->
        Brr.Window.set_location Brr.G.window uri;
        Abb_js.Future.return ()

  let create ph comp state =
    let open Abb_js.Future.Infix_monad in
    let els, set_els = Note.S.create ~eq:( == ) ph in
    let cleanup_ref = ref (fun () -> Abb_js.Future.return ()) in
    Abb_js.Future.fork (comp state >>= handle_output cleanup_ref set_els state)
    >>= fun fut ->
    (cleanup_ref := fun () -> Abb_js.Future.abort fut);
    Abb_js.Future.return (Output.render ~cleanup:(fun () -> !cleanup_ref ()) els)
end

let main app_state f =
  Abb_js.Future.run
    (let open Abb_fut_js.Infix_monad in
     Brr_fut.fut_of_brr_fut (Brr.Ev.next Brr.Ev.load Brr.(Window.as_target G.window))
     >>= fun _ ->
     let state = State.create app_state in
     f state)

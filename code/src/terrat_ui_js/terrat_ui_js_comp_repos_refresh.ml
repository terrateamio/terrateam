module At = Brtl_js2.Brr.At

let tries = 20

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

let wait_for_task client task_id =
  let open Abb_js.Future.Infix_monad in
  let module T = Terrat_api_components.Task in
  Abb_js.sleep 0.2
  >>= fun () ->
  Abb_js_future_combinators.retry
    ~f:(fun () -> Terrat_ui_js_client.task ~id:task_id client)
    ~while_:
      (Abb_js_future_combinators.finite_tries tries (function
          | Error _ -> true
          | Ok T.{ state; _ } ->
              not (CCList.mem ~eq:CCString.equal state [ "completed"; "aborted"; "failed" ])))
    ~betwixt:
      (Abb_js_future_combinators.series ~start:0.5 ~step:(( *. ) 1.5) (fun n _ ->
           Abb_js.sleep (CCFloat.min n 5.0)))

let run' state =
  let open Abb_js.Future.Infix_monad in
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let installation_id = installation.I.id in
  let module T = Terrat_api_components.Task in
  Terrat_ui_js_client.repos_refresh ~installation_id client
  >>= function
  | Ok task_id -> (
      wait_for_task client task_id
      >>= function
      | Ok T.{ state = "completed"; _ } ->
          Abb_js.Future.return (Brtl_js2.Output.redirect ("/i/" ^ installation_id))
      | Ok task -> failwith "nyi"
      | Error _ -> failwith "nyi")
  | Error _ -> failwith "nyi"

let run state = Brtl_js2.Ph.create ph_loading run' state

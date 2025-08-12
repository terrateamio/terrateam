module At = Brtl_js2.Brr.At

let tries = 20

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  module State = Terrat_ui_js_service_state.Make (Vcs)

  let wait_for_task vcs task_id =
    let open Abb_js.Future.Infix_monad in
    let module T = Terrat_api_components.Task in
    Abb_js.sleep 0.2
    >>= fun () ->
    Abb_js_future_combinators.retry
      ~f:(fun () -> Vcs.Api.task ~id:task_id vcs)
      ~while_:
        (Abb_js_future_combinators.finite_tries tries (function
          | Error _ -> true
          | Ok { T.state; _ } ->
              not (CCList.mem ~eq:CCString.equal state [ "completed"; "aborted"; "failed" ])))
      ~betwixt:
        (Abb_js_future_combinators.series ~start:0.5 ~step:(( *. ) 1.5) (fun n _ ->
             Abb_js.sleep (CCFloat.min n 5.0)))

  let run' state =
    let open Abb_js.Future.Infix_monad in
    let app_state = Brtl_js2.State.app_state state in
    let vcs = app_state.State.vcs in
    let { State.selected_installation = installation; _ } = app_state.State.v in
    let module I = Terrat_api_components.Installation in
    let installation_id = Vcs.Installation.id installation in
    let module T = Terrat_api_components.Task in
    Vcs.Api.repos_refresh ~installation_id vcs
    >>= function
    | Ok (Some task_id) -> (
        wait_for_task vcs task_id
        >>= function
        | Ok T.{ state = "completed"; _ } ->
            Abb_js.Future.return
            @@ Brtl_js2.Output.navigate
            @@ Uri.of_string
            @@ Brtl_js2.Path.abs state [ "i"; installation_id ]
        | Ok task -> failwith "nyi"
        | Error _ -> failwith "nyi")
    | Ok None ->
        Abb_js.Future.return
        @@ Brtl_js2.Output.navigate
        @@ Uri.of_string
        @@ Brtl_js2.Path.abs state [ "i"; installation_id ]
    | Error _ -> failwith "nyi"

  let run = Brtl_js2.Ph.create ph_loading run'
end

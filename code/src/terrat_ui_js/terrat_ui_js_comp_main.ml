module At = Brtl_js2.Brr.At

module Rt = struct
  let main consumed_path = Brtl_js2_rtng.(root consumed_path)
  let pull_requests consumed_path = Brtl_js2_rtng.(root consumed_path / "pull-requests")
end

let installation_sel state =
  let module Menu = Brtl_js2.Kit.Ui.Value_selector.Menu in
  let app_state = Brtl_js2.State.app_state state in
  let installations = Terrat_ui_js_state.installations app_state in
  let selected_installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let sel, set_sel = Brtl_js2.Note.S.create ~eq:I.equal selected_installation in
  Menu.el
    (Menu.v'
       ~action:(fun I.{ id; _ } ->
         Brtl_js2.Router.navigate (Brtl_js2.State.router state) ("/i/" ^ id);
         Abb_js.Future.return ())
       (fun I.{ name; _ } -> Jstr.v name)
       installations
       sel)

let nav_bar state =
  let consumed_path = Brtl_js2.State.consumed_path state in
  let nav_bar_div = Brtl_js2.Brr.(El.div ~at:At.[ class' (Jstr.v "nav-bar") ] []) in
  Brtl_js2.R.Elr.def_children
    nav_bar_div
    (Brtl_js2_nav_bar.run
       ~eq:( = )
       ~choices:
         Brtl_js2_nav_bar.Choice.
           [
             create ~value:`Main Brtl_js2.Brr.El.[ txt' "Get Started" ] consumed_path;
             create
               ~value:`Pull_requests
               Brtl_js2.Brr.El.[ txt' "Pull Requests" ]
               (consumed_path ^ "/pull-requests");
           ]
       Brtl_js2_rtng.
         [ Rt.pull_requests consumed_path --> `Pull_requests; Rt.main consumed_path --> `Main ]
       state);
  nav_bar_div

let pull_requests state =
  let consumed_path = Brtl_js2.State.consumed_path state in
  let pull_request_details () = Brtl_js2_rtng.(root consumed_path /% Path.int) in
  let pull_requests () =
    Brtl_js2_rtng.(root consumed_path /? Query.(option (array (string "page"))))
  in
  let pr_event, pr_send = Brtl_js2.Note.E.create () in
  let logr =
    Brtl_js2.Note.E.log pr_event (fun pr ->
        Brtl_js2.Router.navigate
          (Brtl_js2.State.router state)
          (consumed_path
          ^ "/"
          ^ CCInt.to_string pr.Terrat_api_components.Installation_pull_request.pull_number))
  in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       Brtl_js2.Brr.El.
         [
           Brtl_js2.Router_output.create
             state
             (Brtl_js2.R.Elr.with_rem
                (fun () ->
                  Brtl_js2.Note.Logr.destroy' logr;
                  Abb_js.Future.return ())
                (div []))
             Brtl_js2_rtng.
               [
                 pull_request_details () --> Terrat_ui_js_comp_pull_request_details.run;
                 pull_requests () --> Terrat_ui_js_comp_pull_requests_page.run pr_send;
               ];
         ])

let main = Terrat_ui_js_comp_getting_started.run

let run' state =
  let consumed_path = Brtl_js2.State.consumed_path state in
  let app_state = Brtl_js2.State.app_state state in
  let user = Terrat_ui_js_state.user app_state in
  let avatar_url = CCOption.get_or ~default:"" user.Terrat_api_components.User.avatar_url in
  let nav_bar_div = nav_bar state in
  let installation_sel_el = installation_sel state in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       Brtl_js2.Brr.El.
         [
           div
             ~at:Brtl_js2.Brr.At.[ class' (Jstr.v "content") ]
             [
               div
                 ~at:Brtl_js2.Brr.At.[ class' (Jstr.v "header") ]
                 [
                   div
                     [
                       img
                         ~at:
                           Brtl_js2.Brr.At.
                             [ src (Jstr.v "/assets/logo.png"); class' (Jstr.v "h-16") ]
                         ();
                     ];
                   div
                     ~at:At.[ class' (Jstr.v "right") ]
                     [
                       div
                         ~at:At.[ class' (Jstr.v "links") ]
                         [
                           div
                             [
                               a
                                 ~at:
                                   At.
                                     [
                                       v (Jstr.v "target") (Jstr.v "_blank");
                                       href (Jstr.v "https://terrateam.io/docs");
                                     ]
                                 [ txt' "Docs" ];
                             ];
                           div
                             [
                               a
                                 ~at:
                                   At.
                                     [
                                       v (Jstr.v "target") (Jstr.v "_blank");
                                       href (Jstr.v "https://terrateam.io/support");
                                     ]
                                 [ txt' "Support" ];
                             ];
                           div
                             [
                               a
                                 ~at:
                                   At.
                                     [
                                       v (Jstr.v "target") (Jstr.v "_blank");
                                       href (Jstr.v "https://terrateam.io/slack");
                                     ]
                                 [ txt' "Slack" ];
                             ];
                         ];
                       div
                         ~at:Brtl_js2.Brr.At.[ class' (Jstr.v "installation") ]
                         [ span [ txt' "Org:" ]; installation_sel_el ];
                       div
                         ~at:Brtl_js2.Brr.At.[ class' (Jstr.v "avatar") ]
                         [ img ~at:Brtl_js2.Brr.At.[ src (Jstr.v avatar_url) ] () ];
                     ];
                 ];
               nav_bar_div;
               Brtl_js2.Router_output.create
                 state
                 (div ~at:Brtl_js2.Brr.At.[ class' (Jstr.v "main-content") ] [])
                 Brtl_js2_rtng.
                   [
                     Rt.pull_requests consumed_path --> pull_requests;
                     Rt.main consumed_path --> main;
                   ];
             ];
         ])

let run installation_id state =
  let open Abb_js.Future.Infix_monad in
  let client = Brtl_js2.State.app_state state in
  Terrat_ui_js_client.whoami client
  >>= function
  | Ok (Some user) -> (
      let module I = Terrat_api_components.Installation in
      let module R = Terrat_api_user.List_installations.Responses.OK in
      Terrat_ui_js_client.installations client
      >>= function
      | Ok R.{ installations = []; _ } -> assert false
      | Ok R.{ installations; _ } -> (
          match
            CCList.find_opt (fun I.{ id; _ } -> CCString.equal id installation_id) installations
          with
          | Some selected_installation ->
              let installations =
                Brtl_js2.Note.S.const
                  ~eq:(CCList.equal Terrat_api_components.Installation.equal)
                  installations
              in
              let app_state =
                Terrat_ui_js_state.create ~client ~user ~installations ~selected_installation ()
              in
              run' (Brtl_js2.State.with_app_state app_state state)
          | None -> Abb_js.Future.return (Brtl_js2.Output.redirect "/"))
      | Error _ -> failwith "nyi4")
  | Ok None -> Abb_js.Future.return (Brtl_js2.Output.redirect "/login")
  | Error _ -> assert false

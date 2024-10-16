module At = Brtl_js2.Brr.At

module Rt = struct
  let main consumed_path = Brtl_js2_rtng.(root consumed_path)
  let repo_new consumed_path = Brtl_js2_rtng.(root consumed_path / "repos" / "new" /% Path.string)
  let repos_refresh consumed_path = Brtl_js2_rtng.(root consumed_path / "repos" / "refresh")
  let audit_trail consumed_path = Brtl_js2_rtng.(root consumed_path / "audit-trail")

  let audit_trail_detail consumed_path =
    Brtl_js2_rtng.(root consumed_path / "audit-trail" /% Path.string)
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
             create ~value:`Repos Brtl_js2.Brr.El.[ txt' "Repos" ] consumed_path;
             create
               ~value:`Audit_trail
               Brtl_js2.Brr.El.[ txt' "Audit trail" ]
               (consumed_path ^ "/audit-trail");
           ]
       Brtl_js2_rtng.
         [ Rt.audit_trail consumed_path --> `Audit_trail; Rt.main consumed_path --> `Repos ]
       state);
  nav_bar_div

let run' state =
  let consumed_path = Brtl_js2.State.consumed_path state in
  let app_state = Brtl_js2.State.app_state state in
  let server_config = Terrat_ui_js_state.server_config app_state in
  let user = Terrat_ui_js_state.user app_state in
  let avatar_url = CCOption.get_or ~default:"" user.Terrat_api_components.User.avatar_url in
  let nav_bar_div = nav_bar state in
  let installation_sel_el = installation_sel state in
  let module C = Terrat_api_components_server_config in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       Brtl_js2.Brr.El.
         [
           Brtl_js2.Router_output.const
             state
             (div ~at:At.[ class' (Jstr.v "notifications") ] [])
             Terrat_ui_js_comp_notifications.run;
           div
             ~at:At.[ class' (Jstr.v "content") ]
             [
               div
                 ~at:At.[ class' (Jstr.v "header-outer") ]
                 [
                   div
                     ~at:At.[ class' (Jstr.v "header") ]
                     [
                       div
                         ~at:At.[ class' (Jstr.v "left") ]
                         [
                           img ~at:At.[ src (Jstr.v "/assets/logo.svg"); class' (Jstr.v "h-9") ] ();
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
                         ];
                       div
                         ~at:At.[ class' (Jstr.v "right") ]
                         [
                           a
                             ~at:
                               At.
                                 [
                                   class' (Jstr.v "install");
                                   href (Jstr.v server_config.C.github_app_url);
                                 ]
                             [
                               span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "add" ];
                               span [ txt' "Install" ];
                             ];
                           div ~at:At.[ class' (Jstr.v "installation") ] [ installation_sel_el ];
                           div
                             ~at:At.[ class' (Jstr.v "avatar") ]
                             [ img ~at:At.[ src (Jstr.v avatar_url) ] () ];
                         ];
                     ];
                 ];
               nav_bar_div;
               Brtl_js2.Router_output.create
                 state
                 (div ~at:At.[ class' (Jstr.v "main-content") ] [])
                 Brtl_js2_rtng.
                   [
                     Rt.audit_trail_detail consumed_path
                     --> Terrat_ui_js_comp_audit_trail_detail.run;
                     Rt.audit_trail consumed_path --> Terrat_ui_js_comp_audit_trail2.run;
                     Rt.repo_new consumed_path --> Terrat_ui_js_comp_repo_new.run;
                     Rt.repos_refresh consumed_path --> Terrat_ui_js_comp_repos_refresh.run;
                     Rt.main consumed_path --> Terrat_ui_js_comp_repos.run;
                   ];
             ];
         ])

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

let load_info client =
  Abb_js_future_combinators.Infix_result_app.(
    (fun installations server_config -> (installations, server_config))
    <$> Terrat_ui_js_client.installations client
    <*> Terrat_ui_js_client.server_config client)

let run installation_id state =
  let open Abb_js.Future.Infix_monad in
  let client = Brtl_js2.State.app_state state in
  Terrat_ui_js_client.whoami client
  >>= function
  | Ok (Some user) ->
      let module I = Terrat_api_components.Installation in
      let module R = Terrat_api_user.List_installations.Responses.OK in
      Brtl_js2.Ph.create
        ph_loading
        (fun state ->
          load_info client
          >>= function
          | Ok (R.{ installations = []; _ }, _) -> assert false
          | Ok (R.{ installations; _ }, server_config) -> (
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
                    Terrat_ui_js_state.create
                      ~client
                      ~user
                      ~installations
                      ~selected_installation
                      ~server_config
                      ()
                  in
                  run' (Brtl_js2.State.with_app_state app_state state)
              | None -> Abb_js.Future.return (Brtl_js2.Output.navigate (Uri.of_string "/")))
          | Error _ -> failwith "nyi4")
        state
  | Ok None -> Abb_js.Future.return (Brtl_js2.Output.navigate (Uri.of_string "/login"))
  | Error _ -> assert false

module At = Brtl_js2.Brr.At

type create_err = [ `Error ] [@@deriving show]

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  module State = Terrat_ui_js_service_state.Make (Vcs)

  let create vcs = Abb_js.Future.return (Ok { State.vcs; v = () })

  module Installation = struct
    module Runs_detail = Terrat_ui_js_service_comp_runs_detail.Make (Vcs)
    module Runs = Terrat_ui_js_service_comp_runs.Make (Vcs)
    module Repo_new = Terrat_ui_js_service_comp_repo_new.Make (Vcs)
    module Repos_refresh = Terrat_ui_js_service_comp_repos_refresh.Make (Vcs)
    module Repos = Terrat_ui_js_service_comp_repos.Make (Vcs)
    module Notifications = Terrat_ui_js_service_comp_notifications

    module Rt = struct
      let main consumed_path = Brtl_js2_rtng.(root consumed_path)

      let repo_new consumed_path =
        Brtl_js2_rtng.(root consumed_path / "repos" / "new" /% Path.string)

      let repos_refresh consumed_path = Brtl_js2_rtng.(root consumed_path / "repos" / "refresh")
      let runs consumed_path = Brtl_js2_rtng.(root consumed_path / "runs")
      let runs_detail consumed_path = Brtl_js2_rtng.(root consumed_path / "runs" /% Path.string)
    end

    let installation_sel state =
      let module Menu = Brtl_js2.Kit.Ui.Value_selector.Menu in
      let t = Brtl_js2.State.app_state state in
      let { State.selected_installation; installations; _ } = t.State.v in
      let sel, set_sel = Brtl_js2.Note.S.create ~eq:Vcs.Installation.equal selected_installation in
      Menu.el
        (Menu.v'
           ~action:(fun i ->
             Brtl_js2.Router.navigate (Brtl_js2.State.router state) ("/i/" ^ Vcs.Installation.id i);
             Abb_js.Future.return ())
           (fun i -> Jstr.v @@ Vcs.Installation.name i)
           (Brtl_js2.Note.S.const ~eq:(CCList.equal Vcs.Installation.equal) installations)
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
                 create ~value:`Runs Brtl_js2.Brr.El.[ txt' "Runs" ] (consumed_path ^ "/runs");
               ]
           Brtl_js2_rtng.[ Rt.runs consumed_path --> `Runs; Rt.main consumed_path --> `Repos ]
           state);
      nav_bar_div

    let run' notifications state =
      let consumed_path = Brtl_js2.State.consumed_path state in
      let t = Brtl_js2.State.app_state state in
      let user = t.State.v.State.user in
      let avatar_url = Vcs.User.avatar_url user in
      let nav_bar_div = nav_bar state in
      let installation_sel_el = installation_sel state in
      Abb_js.Future.return
        (Brtl_js2.Output.const
           Brtl_js2.Brr.El.
             [
               Brtl_js2.Router_output.const
                 (Brtl_js2.State.with_app_state notifications state)
                 (div ~at:At.[ class' (Jstr.v "notifications") ] [])
                 Notifications.run;
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
                               img
                                 ~at:At.[ src (Jstr.v "/assets/logo.svg"); class' (Jstr.v "h-9") ]
                                 ();
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
                                 ~at:At.[ class' (Jstr.v "install"); href (Jstr.v "/install") ]
                                 [
                                   span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "add" ];
                                   span [ txt' "Install" ];
                                 ];
                               div ~at:At.[ class' (Jstr.v "installation") ] [ installation_sel_el ];
                               div
                                 ~at:At.[ class' (Jstr.v "avatar") ]
                                 [ img ~at:At.[ src (Jstr.v avatar_url) ] () ];
                               div
                                 ~at:At.[ class' (Jstr.v "logout") ]
                                 [ a ~at:At.[ href (Jstr.v "/logout") ] [ txt' "Logout" ] ];
                             ];
                         ];
                     ];
                   nav_bar_div;
                   Brtl_js2.Router_output.create
                     state
                     (div ~at:At.[ class' (Jstr.v "main-content") ] [])
                     Brtl_js2_rtng.
                       [
                         Rt.runs_detail consumed_path --> Runs_detail.run;
                         Rt.runs consumed_path --> Runs.run;
                         Rt.repo_new consumed_path --> Repo_new.run;
                         Rt.repos_refresh consumed_path --> Repos_refresh.run;
                         Rt.main consumed_path --> Repos.run;
                       ];
                 ];
             ])

    let run installation_id state =
      let open Abb_js.Future.Infix_monad in
      let t = Brtl_js2.State.app_state state in
      let vcs = t.State.vcs in
      Abb_js_future_combinators.Infix_result_app.(
        (fun user installations server_config -> (user, installations, server_config))
        <$> Vcs.Api.whoami vcs
        <*> Vcs.Api.installations vcs
        <*> Vcs.Api.server_config vcs)
      >>= function
      | Ok (user, installations, server_config) -> (
          match
            CCList.find_opt
              (fun i -> CCString.equal installation_id (Vcs.Installation.id i))
              installations
          with
          | Some i ->
              let notifications, notify = Notifications.make () in
              let t =
                {
                  t with
                  State.v =
                    { State.user; selected_installation = i; installations; server_config; notify };
                }
              in
              Brtl_js2.Ph.create
                ph_loading
                (fun state -> run' notifications (Brtl_js2.State.with_app_state t state))
                state
          | None -> Abb_js.Future.return (Brtl_js2.Output.navigate (Uri.of_string "/")))
      | Error _ -> raise (Failure "nyi")
  end

  let new_installation_install installation_id state =
    Abb_js.Future.return
      (Brtl_js2.Output.navigate (Uri.of_string ("/i/" ^ installation_id ^ "/repos/refresh")))

  let no_installation state =
    let open Abb_js.Future.Infix_monad in
    let consumed_path = Brtl_js2.State.consumed_path state in
    let t = Brtl_js2.State.app_state state in
    let vcs = t.State.vcs in
    let module R = Terrat_api_user.List_github_installations.Responses.OK in
    Vcs.Api.installations vcs
    >>= function
    | Ok [] -> Vcs.Comp.No_installations.run (Brtl_js2.State.with_app_state vcs state)
    | Ok (i :: _) ->
        Abb_js.Future.return
          (Brtl_js2.Output.navigate (Uri.of_string (consumed_path ^ "/i/" ^ Vcs.Installation.id i)))
    | Error `Forbidden -> assert false
    | Error #Terrat_ui_js_service_vcs.Api.api_err -> raise (Failure "nyi")

  let run state =
    let installation_rt () = Brtl_js2_rtng.(root "" / "i" /% Path.string) in
    let installation_install_rt () = Brtl_js2_rtng.(root "" /? Query.string "installation_id") in
    let install_rt () = Brtl_js2_rtng.(root "" / "install") in
    let no_installation_rt () = Brtl_js2_rtng.(root "") in
    Abb_js.Future.return
    @@ Brtl_js2.Output.const
    @@ [
         Brtl_js2.Router_output.create
           state
           (Brtl_js2.Brr.Document.body Brtl_js2.Brr.G.document)
           Brtl_js2_rtng.
             [
               installation_rt () --> Installation.run;
               installation_install_rt () --> new_installation_install;
               (install_rt ()
               --> fun state ->
               let t = Brtl_js2.State.app_state state in
               let vcs = t.State.vcs in
               Vcs.Comp.Add_installation.run (Brtl_js2.State.with_app_state vcs state));
               no_installation_rt () --> no_installation;
             ];
       ]
end

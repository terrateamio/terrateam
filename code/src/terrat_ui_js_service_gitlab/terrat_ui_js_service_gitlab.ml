module At = Brtl_js2.Brr.At

module Client = struct
  module Http = Abb_js_fetch

  module Io = struct
    type 'a t = 'a Abb_js.Future.t
    type err = Jv.Error.t

    let ( >>= ) = Abb_js.Future.Infix_monad.( >>= )
    let return = Abb_js.Future.return

    let call ?body ~headers ~meth uri =
      let url = Uri.to_string uri in
      let meth =
        match meth with
        | `Get -> `GET
        | `Delete -> `DELETE
        | `Patch -> assert false
        | `Put -> `PUT
        | `Post -> `POST
      in
      Http.fetch ?body ~headers ~meth ~url ()
      >>= function
      | Ok resp ->
          return
            (Ok
               (Openapi.Response.make
                  ~headers:(Http.Response.headers resp)
                  ~request_uri:uri
                  ~status:(Http.Response.status resp)
                  (Http.Response.text resp)))
      | Error (`Js_err err) -> return (Error (`Io_err err))
  end

  module Api = Openapi.Make (Io)

  type t = unit

  let call = Api.call
end

type t = { client : Client.t }

let create () = Abb_js.Future.return (Ok { client = () })

module User = struct
  module U = Terrat_api_components.Gitlab_user

  type t = U.t

  let avatar_url { U.avatar_url; _ } = CCOption.get_or ~default:"" avatar_url
end

module Server_config = struct
  module G = Terrat_api_components.Server_config_gitlab

  type t = {
    server_config : Terrat_api_components.Server_config.t;
    config : Terrat_api_components.Server_config_gitlab.t;
  }

  let vcs_web_base_url { config = { G.web_base_url; _ }; _ } = web_base_url
end

module Installation = struct
  module I = Terrat_api_components.Installation
  module T = Terrat_api_components_tier

  type t = I.t [@@deriving eq]

  let id { I.id; _ } = id
  let name { I.name; _ } = name
  let tier_name { I.tier = { T.name; _ }; _ } = name

  let tier_features { I.tier = { T.features = { T.Features.num_users_per_month; _ }; _ }; _ } =
    { Terrat_ui_js_service_vcs.Tier.num_users_per_month }

  let trial_ends_at { I.trial_ends_at; _ } = CCOption.map Brtl_js2_datetime.of_string trial_ends_at
end

module Api = struct
  let whoami t =
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (Terrat_api_gitlab_user.Whoami.make ())
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK user -> Abb_js.Future.return (Ok user)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let server_config t =
    let module Sc = Terrat_api_components.Server_config in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (Terrat_api_server.Config.make ())
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK ({ Sc.gitlab = Some config; _ } as server_config) ->
        Abb_js.Future.return (Ok { Server_config.server_config; config })
    | `OK _ -> Abb_js.Future.return (Error `Not_found)

  let installations t =
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (Terrat_api_gitlab_installations.List.make ())
    >>= fun resp ->
    let module R = Terrat_api_gitlab_installations.List.Responses.OK in
    match Openapi.Response.value resp with
    | `OK { R.installations } -> Abb_js.Future.return (Ok installations)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let work_manifests ?tz ?page ?limit ?q ?dir ~installation_id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    let module R = Terrat_api_gitlab_installations.List_work_manifests.Responses.OK in
    Client.call
      Terrat_api_gitlab_installations.List_work_manifests.(
        make
          Parameters.(
            make
              ~d:
                (CCOption.map
                   (function
                     | `Asc -> "asc"
                     | `Desc -> "desc")
                   dir)
              ~page
              ~limit
              ~q
              ~tz
              ~installation_id
              ()))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK R.{ work_manifests } ->
        Abb_js.Future.return (Ok (Terrat_ui_js_service_vcs.Page.of_response resp work_manifests))
    | `Bad_request _ as err -> Abb_js.Future.return (Error err)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let work_manifest_outputs ?tz ?page ?limit ?q ?lite ~installation_id ~work_manifest_id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    let module R = Terrat_api_gitlab_installations.Get_work_manifest_outputs.Responses.OK in
    Client.call
      Terrat_api_gitlab_installations.Get_work_manifest_outputs.(
        make Parameters.(make ~page ~limit ~q ~tz ?lite ~installation_id ~work_manifest_id ()))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK { R.steps } ->
        Abb_js.Future.return (Ok (Terrat_ui_js_service_vcs.Page.of_response resp steps))
    | `Bad_request _ as err -> Abb_js.Future.return (Error err)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)
    | `Not_found -> Abb_js.Future.return (Error `Not_found)

  let dirspaces ?tz ?page ?limit ?q ?dir ~installation_id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    let module R = Terrat_api_gitlab_installations.List_dirspaces.Responses.OK in
    Client.call
      Terrat_api_gitlab_installations.List_dirspaces.(
        make
          Parameters.(
            make
              ~d:
                (CCOption.map
                   (function
                     | `Asc -> "asc"
                     | `Desc -> "desc")
                   dir)
              ~page
              ~limit
              ~q
              ~tz
              ~installation_id
              ()))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK { R.dirspaces } ->
        Abb_js.Future.return (Ok (Terrat_ui_js_service_vcs.Page.of_response resp dirspaces))
    | `Bad_request _ as err -> Abb_js.Future.return (Error err)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let repos ?page ~installation_id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    let module R = Terrat_api_gitlab_installations.List_repos.Responses.OK in
    Client.call
      Terrat_api_gitlab_installations.List_repos.(make Parameters.(make ~page ~installation_id ()))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK R.{ repositories } ->
        Abb_js.Future.return (Ok (Terrat_ui_js_service_vcs.Page.of_response resp repositories))
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let repos_refresh ~installation_id t = Abb_js.Future.return (Ok None)
  let task ~id t = raise (Failure "nyi")

  (* API Calls not part of the VCS provider interface *)

  let groups t =
    let module G = Terrat_api_components.Gitlab_group in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (Terrat_api_gitlab_groups.List.make ())
    >>= fun resp ->
    let (`OK groups) = Openapi.Response.value resp in
    Abb_js.Future.return (Ok groups)

  let is_group_member t group_id =
    let module G = Terrat_api_gitlab_groups.Is_member in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call G.(make (Parameters.make ~id:group_id))
    >>= fun resp ->
    let (`OK { G.Responses.OK.result }) = Openapi.Response.value resp in
    Abb_js.Future.return (Ok result)

  let whoareyou t =
    let module U = Terrat_api_components.Gitlab_whoareyou in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (Terrat_api_gitlab_user.Whoareyou.make ())
    >>= fun resp ->
    let (`OK whoareyou) = Openapi.Response.value resp in
    Abb_js.Future.return (Ok whoareyou)

  let installation_webhook t group_id =
    let module W = Terrat_api_gitlab_installations.Get_webhook in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call W.(make (Parameters.make ~id:group_id))
    >>= fun resp ->
    let (`OK webhook) = Openapi.Response.value resp in
    Abb_js.Future.return (Ok webhook)
end

module Comp = struct
  module Login = struct
    type config = Terrat_api_components.Server_config_gitlab.t

    let is_enabled =
      let module C = Terrat_api_components.Server_config in
      function
      | { C.gitlab; _ } -> gitlab

    let run config state =
      let module C = Terrat_api_components.Server_config_gitlab in
      Abb_js.Future.return
        (Brtl_js2.Output.const
           Brtl_js2.Brr.El.
             [
               a
                 ~at:
                   At.
                     [
                       href
                         (Jstr.v
                         @@ Uri.to_string
                         @@ Uri.with_query'
                              (Uri.of_string (config.C.web_base_url ^ "/oauth/authorize"))
                              [
                                ("client_id", config.C.app_id);
                                ("redirect_uri", config.C.redirect_url);
                                ("response_type", "code");
                                ("state", "foobar");
                              ]);
                     ]
                 [
                   Tabler_icons_outline.brand_gitlab ();
                   div [ txt' "Login with GitLab (Beta)" ];
                   Tabler_icons_outline.arrow_narrow_right ();
                 ];
             ])
  end

  module Add_installation = struct
    let group_select_comp state =
      let open Abb_js.Future.Infix_monad in
      let t = Brtl_js2.State.app_state state in
      Api.groups t.client
      >>= function
      | Ok groups ->
          let module G = Terrat_api_components_gitlab_group in
          Abb_js.Future.return
          @@ Brtl_js2.Output.const
          @@ Brtl_js2.Brr.El.
               [
                 h1 [ txt' "Terrateam on GitLab" ];
                 h2 [ txt' "Choose a group to install Terrateam" ];
                 ol
                 @@ CCList.map
                      (fun { G.id = group_id; name } ->
                        li
                          [
                            a
                              ~at:
                                At.
                                  [
                                    href
                                      (Jstr.v
                                         (Brtl_js2.Path.rel
                                            state
                                            [ CCInt.to_string group_id; "user" ]));
                                  ]
                              [ txt' name ];
                          ])
                      groups;
                 a ~at:At.[ href (Jstr.v "/logout") ] [ txt' "Cancel" ];
               ]
      | Error _ -> Abb_js.Future.return @@ Brtl_js2.Output.const @@ Brtl_js2.Brr.El.[ txt' "ERROR" ]

    let add_user_comp group_id state =
      let open Abb_js.Future.Infix_monad in
      let t = Brtl_js2.State.app_state state in
      Api.is_group_member t group_id
      >>= function
      | Ok true ->
          Abb_js.Future.return
          @@ Brtl_js2.Output.navigate
          @@ Uri.of_string
          @@ Brtl_js2.Path.rel state [ ".."; "webhook" ]
      | Ok false -> (
          let module U = Terrat_api_components.Gitlab_whoareyou in
          Api.whoareyou t
          >>= function
          | Ok { U.username; _ } ->
              let check_btn_idle, set_check_btn_idle = Brtl_js2.Note.S.create ~eq:Bool.equal true in
              let check_passed, set_check_passed = Brtl_js2.Note.S.create ~eq:Bool.equal false in
              let check_btn =
                Brtl_js2.Kit.Ui.Button.v'
                  ~class':(Jstr.v "btn-primary")
                  ~enabled:check_btn_idle
                  ~action:(fun () ->
                    Abb_js_future_combinators.with_finally
                      (fun () ->
                        set_check_btn_idle false;
                        Api.is_group_member t group_id
                        >>| function
                        | Ok res -> set_check_passed res
                        | Error _ -> ())
                      ~finally:(fun () ->
                        set_check_btn_idle true;
                        Abb_js.Future.return ()))
                  (Brtl_js2.Note.S.const ~eq:( == ) @@ Brtl_js2.Brr.El.[ txt' "Check" ])
                  ()
              in
              let next_btn =
                Brtl_js2.Kit.Ui.Button.v'
                  ~class':(Jstr.v "btn-primary")
                  ~enabled:check_passed
                  ~action:(fun () ->
                    Brtl_js2.Router.navigate
                      (Brtl_js2.State.router state)
                      (Brtl_js2.Path.rel state [ ".."; "webhook" ]);
                    Abb_js.Future.return ())
                  (Brtl_js2.Note.S.const ~eq:( == ) @@ Brtl_js2.Brr.El.[ txt' "Next" ])
                  ()
              in
              Abb_js.Future.return
              @@ Brtl_js2.Output.const
              @@ Brtl_js2.Brr.El.
                   [
                     h1 [ txt' "Add the Terrateam user to the GitLab group" ];
                     div
                       [
                         txt'
                           "Add the user as a \"Developer\" role.  Click the Check button to \
                            verify the uesr has been added";
                       ];
                     div [ txt' ("Add the the user " ^ username ^ " to the group") ];
                     div
                       ~at:At.[ class' (Jstr.v "movement-btns") ]
                       [
                         div [ Brtl_js2.Kit.Ui.Button.el check_btn ];
                         div [ Brtl_js2.Kit.Ui.Button.el next_btn ];
                       ];
                   ]
          | Error _ ->
              Abb_js.Future.return @@ Brtl_js2.Output.const @@ Brtl_js2.Brr.El.[ txt' "ERROR" ])
      | Error _ -> Abb_js.Future.return @@ Brtl_js2.Output.const @@ Brtl_js2.Brr.El.[ txt' "ERROR" ]

    let add_webhook_comp group_id state =
      let module R = Terrat_api_components.Gitlab_webhook in
      let open Abb_js.Future.Infix_monad in
      let t = Brtl_js2.State.app_state state in
      Api.installation_webhook t group_id
      >>= function
      | Ok { R.webhook_secret = Some webhook_secret; webhook_url; state = webhook_state } ->
          let check_btn_idle, set_check_btn_idle = Brtl_js2.Note.S.create ~eq:Bool.equal true in
          let check_passed, set_check_passed =
            Brtl_js2.Note.S.create ~eq:Bool.equal @@ CCString.equal webhook_state "active"
          in
          let check_btn =
            Brtl_js2.Kit.Ui.Button.v'
              ~class':(Jstr.v "btn-primary")
              ~enabled:check_btn_idle
              ~action:(fun () ->
                Abb_js_future_combinators.with_finally
                  (fun () ->
                    set_check_btn_idle false;
                    Api.installation_webhook t group_id
                    >>= function
                    | Ok { R.state = "active"; _ } ->
                        set_check_passed true;
                        Abb_js.Future.return ()
                    | Ok _ -> Abb_js.Future.return ()
                    | Error _ -> raise (Failure "nyi"))
                  ~finally:(fun () ->
                    set_check_btn_idle true;
                    Abb_js.Future.return ()))
              (Brtl_js2.Note.S.const ~eq:( == ) @@ Brtl_js2.Brr.El.[ txt' "Check" ])
              ()
          in
          let next_btn =
            Brtl_js2.Kit.Ui.Button.v'
              ~class':(Jstr.v "btn-primary")
              ~enabled:check_passed
              ~action:(fun () ->
                Brtl_js2.Router.navigate
                  (Brtl_js2.State.router state)
                  (Brtl_js2.Path.abs state [ "i"; CCInt.to_string group_id ]);
                Abb_js.Future.return ())
              (Brtl_js2.Note.S.const ~eq:( == ) @@ Brtl_js2.Brr.El.[ txt' "Next" ])
              ()
          in
          Abb_js.Future.return
          @@ Brtl_js2.Output.const
          @@ CCList.flatten
          @@ Brtl_js2.Brr.El.
               [
                 [
                   h1 [ txt' "Terrateam on GitLab" ];
                   h2 [ txt' "Add the Terrateam webhook to your repository" ];
                   div
                     [
                       txt'
                         "Add the following webhook to all projects in this group that you want \
                          Terrateam to operate on";
                     ];
                   div
                     [
                       txt'
                         "After you have added the webhook, test the webhook with a Push Event \
                          then click the Check to verify the webhook was received.";
                     ];
                   div [ txt' webhook_url ];
                   div [ txt' "Use the following webhook secret" ];
                   div [ txt' webhook_secret ];
                   div
                     ~at:At.[ class' (Jstr.v "movement-btns") ]
                     [
                       div [ Brtl_js2.Kit.Ui.Button.el check_btn ];
                       div [ Brtl_js2.Kit.Ui.Button.el next_btn ];
                     ];
                 ];
               ]
      | Ok _ | Error _ ->
          Abb_js.Future.return @@ Brtl_js2.Output.const @@ Brtl_js2.Brr.El.[ txt' "ERROR" ]

    let run state =
      let consumed_path = Brtl_js2.State.consumed_path state in
      let root_rt () = Brtl_js2_rtng.(root consumed_path) in
      let add_rt () = Brtl_js2_rtng.(root_rt () / "add") in
      let add_user_rt () = Brtl_js2_rtng.(add_rt () /% Path.int / "user") in
      let add_webhook_rt () = Brtl_js2_rtng.(add_rt () /% Path.int / "webhook") in
      Abb_js.Future.return
      @@ Brtl_js2.Output.const
      @@ Brtl_js2.Brr.El.
           [
             Brtl_js2.Router_output.create
               state
               (div ~at:At.[ class' (Jstr.v "gitlab-add-installation") ] [])
               Brtl_js2_rtng.
                 [
                   add_user_rt () --> add_user_comp;
                   add_webhook_rt () --> add_webhook_comp;
                   add_rt () --> group_select_comp;
                   (root_rt ()
                   --> fun _ ->
                   Abb_js.Future.return
                   @@ Brtl_js2.Output.navigate
                   @@ Uri.of_string
                   @@ Brtl_js2.Path.rel state [ "add" ]);
                 ];
           ]
  end

  module No_installations = struct
    let run state =
      Abb_js.Future.return
      @@ Brtl_js2.Output.navigate
      @@ Uri.of_string
      @@ Brtl_js2.Path.abs state [ "install" ]
  end

  module Quickstart = struct
    let run state =
      let open Brtl_js2.Brr.El in
      Abb_js.Future.return
        (Brtl_js2.Output.const
           [
             div
               ~at:At.[ class' (Jstr.v "quickstart-page") ]
               [
                 div
                   ~at:At.[ class' (Jstr.v "quickstart-header") ]
                   [
                     img
                       ~at:At.[ src (Jstr.v "/assets/logo.svg"); class' (Jstr.v "quickstart-logo") ]
                       ();
                     h1
                       ~at:At.[ class' (Jstr.v "quickstart-welcome") ]
                       [ txt' "Welcome to Terrateam" ];
                     p
                       ~at:At.[ class' (Jstr.v "quickstart-subtitle") ]
                       [ txt' "Choose your path to get started with Terraform automation" ];
                   ];
                 div
                   ~at:At.[ class' (Jstr.v "quickstart-options") ]
                   [
                     div
                       ~at:At.[ class' (Jstr.v "quickstart-option") ]
                       [
                         div
                           ~at:At.[ class' (Jstr.v "quickstart-option-content") ]
                           [
                             div
                               ~at:At.[ class' (Jstr.v "quickstart-option-header") ]
                               [
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons quickstart-icon") ]
                                   [ txt' "play_circle_filled" ];
                                 h3
                                   ~at:At.[ class' (Jstr.v "quickstart-title") ]
                                   [ txt' "Try Demo" ];
                               ];
                             p
                               ~at:At.[ class' (Jstr.v "quickstart-description") ]
                               [ txt' "See Terraform plans instantly" ];
                             ul
                               ~at:At.[ class' (Jstr.v "quickstart-features") ]
                               [
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "One click setup";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Instant preview";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "No config needed";
                                   ];
                               ];
                             div
                               ~at:At.[ class' (Jstr.v "quickstart-meta") ]
                               [
                                 span
                                   ~at:At.[ class' (Jstr.v "quickstart-note") ]
                                   [ txt' "Safe sandbox" ];
                                 span ~at:At.[ class' (Jstr.v "quickstart-time") ] [ txt' "2 min" ];
                               ];
                           ];
                         div
                           ~at:At.[ class' (Jstr.v "quickstart-option-footer") ]
                           [
                             a
                               ~at:
                                 At.
                                   [
                                     class' (Jstr.v "btn-primary quickstart-button");
                                     href
                                       (Jstr.v
                                          "https://docs.terrateam.io/getting-started/quickstart-guide#option-1-try-the-demo-recommended");
                                     v (Jstr.v "target") (Jstr.v "_blank");
                                   ]
                               [
                                 txt' "Start";
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons button-icon") ]
                                   [ txt' "chevron_right" ];
                               ];
                           ];
                       ];
                     div
                       ~at:At.[ class' (Jstr.v "quickstart-option") ]
                       [
                         div
                           ~at:At.[ class' (Jstr.v "quickstart-option-content") ]
                           [
                             div
                               ~at:At.[ class' (Jstr.v "quickstart-option-header") ]
                               [
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons quickstart-icon") ]
                                   [ txt' "link" ];
                                 h3
                                   ~at:At.[ class' (Jstr.v "quickstart-title") ]
                                   [ txt' "Connect Repo" ];
                               ];
                             p
                               ~at:At.[ class' (Jstr.v "quickstart-description") ]
                               [ txt' "Connect your Terraform repo" ];
                             ul
                               ~at:At.[ class' (Jstr.v "quickstart-features") ]
                               [
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Quick install";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Auto setup";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Live in minutes";
                                   ];
                               ];
                             div
                               ~at:At.[ class' (Jstr.v "quickstart-meta") ]
                               [
                                 span
                                   ~at:At.[ class' (Jstr.v "quickstart-note") ]
                                   [ txt' "Admin access needed" ];
                                 span ~at:At.[ class' (Jstr.v "quickstart-time") ] [ txt' "5 min" ];
                               ];
                           ];
                         div
                           ~at:At.[ class' (Jstr.v "quickstart-option-footer") ]
                           [
                             a
                               ~at:
                                 At.
                                   [
                                     class' (Jstr.v "btn-primary quickstart-button");
                                     href
                                       (Jstr.v
                                          "https://docs.terrateam.io/getting-started/quickstart-guide#option-2-set-up-your-own-repository");
                                     v (Jstr.v "target") (Jstr.v "_blank");
                                   ]
                               [
                                 txt' "Connect";
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons button-icon") ]
                                   [ txt' "chevron_right" ];
                               ];
                           ];
                       ];
                   ];
               ];
           ])
  end
end

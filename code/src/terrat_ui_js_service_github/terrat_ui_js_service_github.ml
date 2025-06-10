module At = Brtl_js2.Brr.At

module Client = struct
  module Http = Abb_js_fetch

  module Io = struct
    type 'a t = 'a Abb_js.Future.t
    type err = Jv.Error.t

    let ( >>= ) = Abb_js.Future.Infix_monad.( >>= )
    let return = Abb_js.Future.return

    let call ?body ~headers ~meth url =
      let url = Uri.to_string url in
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
  module U = Terrat_api_components.Github_user

  type t = U.t

  let avatar_url { U.avatar_url; _ } = CCOption.get_or ~default:"" avatar_url
end

module Server_config = struct
  module G = Terrat_api_components.Server_config_github

  type t = {
    server_config : Terrat_api_components.Server_config.t;
    config : Terrat_api_components.Server_config_github.t;
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
    Client.call (Terrat_api_github_user.Whoami.make ())
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
    | `OK ({ Sc.github = Some config; _ } as server_config) ->
        Abb_js.Future.return (Ok { Server_config.server_config; config })
    | `OK _ -> Abb_js.Future.return (Error `Not_found)

  let installations t =
    let module I = Terrat_api_user.List_github_installations in
    let module R = I.Responses.OK in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (I.make ())
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK { R.installations } -> Abb_js.Future.return (Ok installations)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let work_manifests ?tz ?page ?limit ?q ?dir ~installation_id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    let module R = Terrat_api_installations.List_work_manifests.Responses.OK in
    Client.call
      Terrat_api_installations.List_work_manifests.(
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
    let module R = Terrat_api_installations.Get_work_manifest_outputs.Responses.OK in
    Client.call
      Terrat_api_installations.Get_work_manifest_outputs.(
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
    let module R = Terrat_api_installations.List_dirspaces.Responses.OK in
    Client.call
      Terrat_api_installations.List_dirspaces.(
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
    let module R = Terrat_api_installations.List_repos.Responses.OK in
    Client.call
      Terrat_api_installations.List_repos.(make Parameters.(make ~page ~installation_id ()))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK R.{ repositories } ->
        Abb_js.Future.return (Ok (Terrat_ui_js_service_vcs.Page.of_response resp repositories))
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let repos_refresh ~installation_id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    let module R = Terrat_api_installations.Repo_refresh.Responses.OK in
    Client.call Terrat_api_installations.Repo_refresh.(make Parameters.(make ~installation_id))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK R.{ id } -> Abb_js.Future.return (Ok id)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)

  let task ~id t =
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call Terrat_api_tasks.Get.(make Parameters.(make ~id))
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK r -> Abb_js.Future.return (Ok r)
    | `Forbidden -> Abb_js.Future.return (Error `Forbidden)
end

module Comp = struct
  module Login = struct
    type config = Terrat_api_components.Server_config_github.t

    let is_enabled =
      let module C = Terrat_api_components.Server_config in
      function
      | { C.github } -> github

    let run config state =
      let module C = Terrat_api_components.Server_config_github in
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
                            (config.C.web_base_url
                            ^ "/login/oauth/authorize?client_id="
                            ^ config.C.app_client_id));
                     ]
                 [
                   Tabler_icons_filled.brand_github ();
                   div [ txt' "Login with GitHub" ];
                   Tabler_icons_outline.arrow_narrow_right ();
                 ];
             ])
  end

  module No_installations = struct
    let run state =
      let module C = Terrat_api_components.Server_config_github in
      let open Abb_js.Future.Infix_monad in
      let vcs = Brtl_js2.State.app_state state in
      Api.server_config vcs
      >>= function
      | Ok { Server_config.config; _ } ->
          Abb_js.Future.return (Brtl_js2.Output.navigate (Uri.of_string config.C.app_url))
      | Error _ -> raise (Failure "nyi")
  end

  module Add_installation = struct
    let run = No_installations.run
  end
end

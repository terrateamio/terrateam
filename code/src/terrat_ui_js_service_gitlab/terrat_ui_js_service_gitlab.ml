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
  type t = unit [@@deriving eq]

  let id t = raise (Failure "nyi")
  let name t = raise (Failure "nyi")
  let tier_name t = raise (Failure "nyi")
  let tier_features t = raise (Failure "nyi")
  let trial_ends_at t = raise (Failure "nyi")
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

  let installations t = Abb_js.Future.return (Ok [])
  let work_manifests ?tz ?page ?limit ?q ?dir ~installation_id t = raise (Failure "nyi")

  let work_manifest_outputs ?tz ?page ?limit ?q ?lite ~installation_id ~work_manifest_id t =
    raise (Failure "nyi")

  let dirspaces ?tz ?page ?limit ?q ?dir ~installation_id t = raise (Failure "nyi")
  let repos ?page ~installation_id t = raise (Failure "nyi")
  let repos_refresh ~installation_id t = raise (Failure "nyi")
  let task ~id t = raise (Failure "nyi")

  (* API Calls not part of the VCS provider interface *)

  let groups t =
    let module G = Terrat_api_components.Gitlab_group in
    let open Abb_js_future_combinators.Infix_result_monad in
    Client.call (Terrat_api_gitlab_groups.List.make ())
    >>= fun resp ->
    match Openapi.Response.value resp with
    | `OK groups -> Abb_js.Future.return (Ok groups)
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
                   div [ txt' "Login with GitLab" ];
                   Tabler_icons_outline.arrow_narrow_right ();
                 ];
             ])
  end

  module No_installations = struct
    let run state =
      let open Abb_js.Future.Infix_monad in
      let t = Brtl_js2.State.app_state state in
      Api.groups t.client
      >>= function
      | Ok groups ->
          Abb_js.Future.return
          @@ Brtl_js2.Output.const
          @@ Brtl_js2.Brr.El.[ a ~at:At.[ href (Jstr.v "/logout") ] [ txt' "Logout" ] ]
      | Error _ -> Abb_js.Future.return @@ Brtl_js2.Output.const @@ Brtl_js2.Brr.El.[ txt' "ERROR" ]
  end

  module Add_installation = struct
    let run state = Abb_js.Future.return @@ Brtl_js2.Output.const @@ Brtl_js2.Brr.El.[ txt' "nyi" ]
  end
end

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

module User = struct
  type t = Terrat_api_components.Github_user.t
end

module Server_config = struct
  type t = {
    server_config : Terrat_api_components.Server_config.t;
    config : Terrat_api_components.Server_config_github.t;
  }
end

module Installation = struct
  type t = Terrat_api_components.Installation.t
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
end

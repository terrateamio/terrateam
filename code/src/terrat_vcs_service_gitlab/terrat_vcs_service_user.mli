module Oauth : sig
  module Http : module type of Abb_curl.Make (Abb)

  type authorize_err =
    [ `Authorize_err of string
    | Http.request_err
    ]
  [@@deriving show]

  type access_token_err =
    [ `Refresh_err of string
    | `Bad_refresh_token
    | `User_not_found of Terrat_user.t
    | Pgsql_io.err
    | Http.request_err
    ]
  [@@deriving show]

  module Response : sig
    type t = {
      access_token : string;
      scope : string;
      token_type : string;
      refresh_token : string option; [@default None]
      refresh_token_expires_in : int option; [@default None]
      expires_in : int option; [@default None]
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  val authorize :
    config:Terrat_config.Gitlab.t ->
    server_api_base:string ->
    string ->
    (Response.t, [> authorize_err ]) result Abb.Future.t

  val access_token :
    config:Terrat_config.Gitlab.t ->
    Pgsql_io.t ->
    Terrat_user.t ->
    (string, [> access_token_err ]) result Abb.Future.t
end

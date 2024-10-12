type err =
  [ `Conversion_err of string * string Openapi.Response.t
  | `Missing_response of string Openapi.Response.t
  | `Io_err of Jv.Error.t
  | `Forbidden
  | `Not_found
  ]
[@@deriving show]

type work_manifests_err =
  [ err
  | `Bad_request of Terrat_api_installations.List_work_manifests.Responses.Bad_request.t
  ]
[@@deriving show]

type t

val create : unit -> t

val whoami :
  t ->
  ( Terrat_api_components.User.t option,
    [> `Conversion_err of string * string Openapi.Response.t
    | `Missing_response of string Openapi.Response.t
    | `Io_err of Jv.Error.t
    ] )
  result
  Abb_js.Future.t

val client_id : t -> (string, [> err ]) result Abb_js.Future.t

val installations :
  t -> (Terrat_api_user.List_installations.Responses.OK.t, [> err ]) result Abb_js.Future.t

val work_manifests :
  ?tz:string ->
  ?page:string list ->
  ?q:string ->
  ?dir:[ `Asc | `Desc ] ->
  installation_id:string ->
  t ->
  ( Terrat_api_components.Installation_work_manifest.t Brtl_js2_page.Page.t,
    [> work_manifests_err ] )
  result
  Abb_js.Future.t

val pull_requests :
  ?page:string list ->
  ?pull_number:int ->
  installation_id:string ->
  t ->
  (Terrat_api_components.Installation_pull_request.t Brtl_js2_page.Page.t, [> err ]) result
  Abb_js.Future.t

val repos :
  ?page:string list ->
  installation_id:string ->
  t ->
  (Terrat_api_components.Installation_repo.t Brtl_js2_page.Page.t, [> err ]) result Abb_js.Future.t

val repos_refresh : installation_id:string -> t -> (string, [> err ]) result Abb_js.Future.t
val task : id:string -> t -> (Terrat_api_components.Task.t, [> err ]) result Abb_js.Future.t
val server_config : t -> (Terrat_api_components.Server_config.t, [> err ]) result Abb_js.Future.t

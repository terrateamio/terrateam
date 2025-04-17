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

type work_manifest_outputs_err =
  [ err
  | `Bad_request of Terrat_api_installations.Get_work_manifest_outputs.Responses.Bad_request.t
  ]
[@@deriving show]

type dirspaces_err =
  [ err
  | `Bad_request of Terrat_api_installations.List_dirspaces.Responses.Bad_request.t
  ]
[@@deriving show]

type t

val create : unit -> t
val logout : t -> (unit, [> err ]) result Abb_js.Future.t
val whoami : t -> (Terrat_api_components.User.t option, [> err ]) result Abb_js.Future.t
val task : id:string -> t -> (Terrat_api_components.Task.t, [> err ]) result Abb_js.Future.t
val server_config : t -> (Terrat_api_components.Server_config.t, [> err ]) result Abb_js.Future.t

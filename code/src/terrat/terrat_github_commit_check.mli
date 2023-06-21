type err = Githubc2_abb.call_err [@@deriving show]

type list_err =
  [ err
  | `Commit_check_list_err of string
  ]
[@@deriving show]

val create :
  config:Terrat_config.t ->
  access_token:string ->
  owner:string ->
  repo:string ->
  ref_:string ->
  Terrat_commit_check.t list ->
  (unit, [> err ]) result Abb.Future.t

val list :
  config:Terrat_config.t ->
  access_token:string ->
  owner:string ->
  repo:string ->
  ref_:string ->
  unit ->
  (Terrat_commit_check.t list, [> list_err ]) result Abb.Future.t

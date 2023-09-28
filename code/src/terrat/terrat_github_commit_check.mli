type err = Githubc2_abb.call_err [@@deriving show]

type list_err =
  [ err
  | `Commit_check_list_err of string
  ]
[@@deriving show]

val create :
  owner:string ->
  repo:string ->
  ref_:string ->
  checks:Terrat_commit_check.t list ->
  Githubc2_abb.t ->
  (unit, [> err ]) result Abb.Future.t

val list :
  log_id:string ->
  owner:string ->
  repo:string ->
  ref_:string ->
  Githubc2_abb.t ->
  (Terrat_commit_check.t list, [> list_err ]) result Abb.Future.t

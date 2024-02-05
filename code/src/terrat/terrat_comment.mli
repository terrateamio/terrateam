type t =
  | Plan of { tag_query : Terrat_tag_query.t }
  | Apply of { tag_query : Terrat_tag_query.t }
  | Apply_autoapprove of { tag_query : Terrat_tag_query.t }
  | Apply_force of { tag_query : Terrat_tag_query.t }
  | Unlock of string list
  | Help
  | Feedback of string
  | Repo_config
  | Index

type err =
  [ `Not_terrateam
  | `Unknown_action of string
  | Terrat_tag_query_ast.err
  ]
[@@deriving show]

val parse : string -> (t, [> err ]) result

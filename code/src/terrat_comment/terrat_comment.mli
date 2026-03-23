type t =
  | Apply of { tag_query : Terrat_tag_query.t }
  | Apply_autoapprove of { tag_query : Terrat_tag_query.t }
  | Apply_cancel
  | Apply_force of { tag_query : Terrat_tag_query.t }
  | Apply_scheduled of {
      tag_query : Terrat_tag_query.t;
      scheduled_at : string;
    }
  | Feedback of string
  | Gate_approval of { tokens : string list }
  | Help
  | Index
  | Plan of { tag_query : Terrat_tag_query.t }
  | Repo_config
  | Unlock of string list

type err =
  [ `Not_terrateam
  | `Unknown_action of string
  | `Invalid_schedule_time_err of string
  | Terrat_tag_query_ast.err
  ]
[@@deriving show]

val parse : string -> (t, [> err ]) result
val to_string : t -> string

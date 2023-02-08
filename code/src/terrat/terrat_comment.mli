type t =
  | Plan of { tag_query : Terrat_tag_query.t }
  | Apply of { tag_query : Terrat_tag_query.t }
  | Apply_autoapprove of { tag_query : Terrat_tag_query.t }
  | Apply_force of { tag_query : Terrat_tag_query.t }
  | Unlock of string list
  | Help
  | Feedback of string

type err =
  [ `Not_terrateam
  | `Unknown_action of string
  ]

val parse : string -> (t, [> err ]) result

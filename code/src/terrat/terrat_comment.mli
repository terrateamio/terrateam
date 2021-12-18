type t =
  | Plan of { tag_query : Terrat_tag_set.t }
  | Apply of { tag_query : Terrat_tag_set.t }
  | Unlock
  | Help

type err =
  [ `Not_terrateam
  | `Unknown_action of string
  ]

val parse : string -> (t, [> err ]) result

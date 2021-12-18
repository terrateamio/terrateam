type t =
  | Plan of { tag_query : Terrat_tag_set.t }
  | Apply of { tag_query : Terrat_tag_set.t }
  | Unlock
  | Help

type err =
  [ `Not_terrateam
  | `Unknown_action of string
  ]

let parse s =
  let split_s = s |> CCString.split_on_char ' ' |> CCList.filter CCFun.(CCString.is_empty %> not) in
  match split_s with
  | [ "terrateam"; "unlock" ] -> Ok Unlock
  | "terrateam" :: "plan" :: tag_query -> Ok (Plan { tag_query = Terrat_tag_set.of_list tag_query })
  | "terrateam" :: "apply" :: tag_query ->
      Ok (Apply { tag_query = Terrat_tag_set.of_list tag_query })
  | "terrateam" :: "help" :: _ -> Ok Help
  | "terrateam" :: action :: _ -> Error (`Unknown_action action)
  | "terrateam" :: _ -> Error (`Unknown_action "")
  | _ -> Error `Not_terrateam

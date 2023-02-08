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

let parse s =
  let split_s =
    match CCString.Split.left ~by:" " (CCString.trim s) with
    | Some ("terrateam", action_rest) -> (
        match CCString.Split.left ~by:" " (CCString.trim action_rest) with
        | Some (action, rest) -> Some (action, rest)
        | None -> Some (action_rest, ""))
    | _ -> None
  in
  match split_s with
  | Some ("unlock", rest) ->
      Ok
        (Unlock
           (rest
           |> CCString.split_on_char ' '
           |> CCList.map CCString.trim
           |> CCList.filter CCFun.(CCString.is_empty %> not)))
  | Some ("plan", rest) -> Ok (Plan { tag_query = Terrat_tag_query.of_string rest })
  | Some ("apply", rest) -> Ok (Apply { tag_query = Terrat_tag_query.of_string rest })
  | Some ("apply-autoapprove", rest) ->
      Ok (Apply_autoapprove { tag_query = Terrat_tag_query.of_string rest })
  | Some ("apply-force", rest) -> Ok (Apply_force { tag_query = Terrat_tag_query.of_string rest })
  | Some ("help", _) -> Ok Help
  | Some ("feedback", rest) -> Ok (Feedback rest)
  | Some (action, rest) -> Error (`Unknown_action action)
  | None -> Error `Not_terrateam

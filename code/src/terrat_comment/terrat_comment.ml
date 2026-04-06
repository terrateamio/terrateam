let trigger_words = [ "terrateam"; "terraform"; "tofu" ]

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

let parse s =
  let s =
    (* In GitLab, the automatic copy of a triple backtick text adds the single
       backticks, so we trim those off and any white space.  This makes it so
       people can drop comments like `terrateam plan` and it will still work.
       We trim twice, once for outside the single backticks and once for
       inside. *)
    s
    |> CCString.trim
    |> CCString.drop_while (( = ) '`')
    |> CCString.rdrop_while (( = ) '`')
    |> CCString.trim
  in
  let split_s =
    match CCString.Split.left ~by:" " s with
    | Some (trigger_word, action_rest)
      when CCList.mem ~eq:CCString.equal (CCString.lowercase_ascii trigger_word) trigger_words -> (
        match CCString.Split.left ~by:" " (CCString.trim action_rest) with
        | Some (action, rest) -> Some (action, rest)
        | None -> Some (action_rest, ""))
    | _ -> None
  in
  let open CCResult.Infix in
  match split_s with
  | Some ("unlock", rest) ->
      Ok
        (Unlock
           (rest
           |> CCString.split_on_char ' '
           |> CCList.map CCString.trim
           |> CCList.filter CCFun.(CCString.is_empty %> not)))
  | Some ("plan", rest) ->
      Terrat_tag_query.of_string rest >>= fun tag_query -> Ok (Plan { tag_query })
  | Some ("apply", rest) -> (
      let validate_scheduled_at s =
        let s = CCString.trim s in
        if CCString.is_empty s then Error (`Invalid_schedule_time_err "empty timestamp")
        else if not (CCString.suffix ~suf:"Z" s) then
          Error (`Invalid_schedule_time_err (s ^ " (must be in UTC, ending with Z)"))
        else Ok s
      in
      let rest = CCString.trim rest in
      match CCString.Split.right ~by:" at " rest with
      | Some (tag_query_str, scheduled_at) ->
          validate_scheduled_at scheduled_at
          >>= fun scheduled_at ->
          Terrat_tag_query.of_string tag_query_str
          >>= fun tag_query -> Ok (Apply_scheduled { tag_query; scheduled_at })
      | None when CCString.prefix ~pre:"at " rest ->
          let scheduled_at = CCString.trim (CCString.drop (String.length "at ") rest) in
          validate_scheduled_at scheduled_at
          >>= fun scheduled_at ->
          Terrat_tag_query.of_string ""
          >>= fun tag_query -> Ok (Apply_scheduled { tag_query; scheduled_at })
      | None -> Terrat_tag_query.of_string rest >>= fun tag_query -> Ok (Apply { tag_query }))
  | Some ("apply-cancel", _) -> Ok Apply_cancel
  | Some ("apply-autoapprove", rest) ->
      Terrat_tag_query.of_string rest >>= fun tag_query -> Ok (Apply_autoapprove { tag_query })
  | Some ("apply-force", rest) ->
      Terrat_tag_query.of_string rest >>= fun tag_query -> Ok (Apply_force { tag_query })
  | Some ("help", _) -> Ok Help
  | Some ("feedback", rest) -> Ok (Feedback rest)
  | Some ("repo-config", _) -> Ok Repo_config
  | Some ("index", _) -> Ok Index
  | Some ("gate", rest) -> (
      match CCString.Split.left ~by:" " (CCString.trim rest) with
      | Some ("approve", tokens) ->
          Ok
            (Gate_approval
               { tokens = CCList.map CCString.trim @@ CCString.split_on_char ' ' tokens })
      | Some (action, _) -> Error (`Unknown_action action)
      | None -> Error (`Unknown_action s))
  | Some (action, rest) -> Error (`Unknown_action action)
  | None -> Error `Not_terrateam

let to_string = function
  | Apply { tag_query } -> "terrateam apply " ^ Terrat_tag_query.to_string tag_query
  | Apply_autoapprove { tag_query } ->
      "terrateam apply-autoapprove " ^ Terrat_tag_query.to_string tag_query
  | Apply_cancel -> "terrateam apply-cancel"
  | Apply_force { tag_query } -> "terrateam apply-force " ^ Terrat_tag_query.to_string tag_query
  | Apply_scheduled { tag_query; scheduled_at } ->
      "terrateam apply " ^ Terrat_tag_query.to_string tag_query ^ " at " ^ scheduled_at
  | Feedback feedback -> "terrateam feedback " ^ feedback
  | Gate_approval { tokens } -> "terrateam gate approval " ^ CCString.concat " " tokens
  | Help -> "terrateam help"
  | Index -> "terrateam index"
  | Plan { tag_query } -> "terrateam plan " ^ Terrat_tag_query.to_string tag_query
  | Repo_config -> "terrateam repo-config"
  | Unlock ids -> "terrateam unlock " ^ CCString.concat " " ids

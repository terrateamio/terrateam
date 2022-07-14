module Key = struct
  type t =
    | Section of string
    | Subsection of (string * string)
  [@@deriving show, ord]

  let section s = Section (CCString.lowercase_ascii s)
  let subsection s ss = Subsection (CCString.lowercase_ascii s, ss)
end

module Config = CCMap.Make (Key)
module Value = CCMap.Make (CCString)

type t = string list Value.t Config.t

type err =
  [ `Premature_eof_err
  | `Syntax_err of int
  ]
[@@deriving show]

let rec parse' config =
  let open Git_config_lexer.Token in
  function
  | [] -> Ok config
  | Left_bracket :: String section :: Right_bracket :: rest ->
      parse_section' config (Key.Section section) rest
  | Left_bracket :: String section :: String subsection :: Right_bracket :: rest ->
      parse_section' config (Key.Subsection (section, subsection)) rest
  | _ -> assert false

and parse_section' config section =
  let open Git_config_lexer.Token in
  function
  | [] -> Ok config
  | Left_bracket :: String section :: Right_bracket :: rest ->
      parse_section' config (Key.Section section) rest
  | Left_bracket :: String section :: String subsection :: Right_bracket :: rest ->
      parse_section' config (Key.Subsection (section, subsection)) rest
  | String name :: Equal :: String value :: rest ->
      (* TODO: Not handling values properly.  I don't strip quotes, don't handle
         escapes, nothing *)
      let name = CCString.lowercase_ascii name in
      let value = CCString.trim value in
      let config =
        Config.update
          section
          (function
            | None -> Some (Value.singleton name [ value ])
            | Some vs ->
                Some
                  (Value.update
                     name
                     (function
                       | None -> Some [ value ]
                       | Some vs -> Some (vs @ [ value ]))
                     vs))
          config
      in
      parse_section' config section rest
  | String name :: rest ->
      let name = CCString.lowercase_ascii name in
      let config =
        Config.update
          section
          (function
            | None -> Some (Value.singleton name [ "true" ])
            | Some vs ->
                Some
                  (Value.update
                     name
                     (function
                       | None -> Some [ "true" ]
                       | Some vs -> Some (vs @ [ "true" ]))
                     vs))
          config
      in
      parse_section' config section rest
  | _ -> assert false

let parse tokens =
  let config = Config.empty in
  parse' config tokens

let empty = Config.empty

let of_string s =
  let buf = Sedlexing.Utf8.from_string s in
  match Git_config_lexer.tokenize buf with
  | Ok tokens -> parse tokens
  | Error (`Expected_section_header line) | Error (`Syntax line) -> Error (`Syntax_err line)
  | Error `Premature_eof -> Error `Premature_eof_err

let to_list t = t |> Config.to_list |> CCList.map (fun (k, v) -> (k, Value.to_list v))

let value section name t =
  let open CCOption.Infix in
  Config.find_opt section t >>= fun vs -> Value.find_opt (CCString.lowercase_ascii name) vs

type err =
  [ `Parse_json_error of string
  | `Bad_signature of string * string
  | `Missing_signature
  | `Missing_event_type
  | `Unknown_action of string
  ]
[@@deriving show]

let decode headers body =
  try
    let json = Yojson.Safe.from_string body in
    match Terrat_github_webhooks.Event.of_yojson json with
    | Ok event -> Ok event
    | Error err -> Error (`Parse_json_error err)
  with _ -> Error (`Parse_json_error body)

let run ?secret headers body =
  match secret with
  | Some secret -> (
      match
        CCOpt.flat_map
          (CCString.Split.left ~by:"=")
          (Cohttp.Header.get headers "x-hub-signature-256")
      with
      | Some ("sha256", x_hub_sig) ->
          let x_hub_sig = Cstruct.of_hex x_hub_sig in
          let computed_sig =
            Mirage_crypto.Hash.SHA256.hmac ~key:(Cstruct.of_string secret) (Cstruct.of_string body)
          in
          if Cstruct.equal x_hub_sig computed_sig then decode headers body
          else Error (`Bad_signature (Cstruct.to_string computed_sig, Cstruct.to_string x_hub_sig))
      | _ -> Error `Missing_signature)
  | None -> decode headers body

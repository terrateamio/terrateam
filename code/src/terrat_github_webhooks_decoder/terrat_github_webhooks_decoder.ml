type err =
  [ `Parse_json_error of string
  | `Bad_signature of string * string
  | `Missing_signature
  | `Missing_event_type
  | `Unknown_action of string
  ]
[@@deriving show]

let decode _headers body =
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
        CCOption.flat_map
          (CCString.Split.left ~by:"=")
          (Cohttp.Header.get headers "x-hub-signature-256")
      with
      | Some ("sha256", x_hub_sig) -> (
          let computed_sig = Digestif.SHA256.hmac_string ~key:secret body in
          match Digestif.SHA256.of_hex_opt x_hub_sig with
          | Some provided_sig when Digestif.SHA256.equal provided_sig computed_sig ->
              decode headers body
          | Some provided_sig ->
              Error
                (`Bad_signature
                   ( Digestif.SHA256.to_raw_string computed_sig,
                     Digestif.SHA256.to_raw_string provided_sig ))
          | None -> Error (`Bad_signature (Digestif.SHA256.to_raw_string computed_sig, x_hub_sig)))
      | _ -> Error `Missing_signature)
  | None -> decode headers body

type err = [ `Parse_json_error of string ] [@@deriving show]

let decode body =
  try
    let json = Yojson.Safe.from_string body in
    match Gitlab_webhooks.Event.of_yojson json with
    | Ok event -> Ok event
    | Error err -> Error (`Parse_json_error err)
  with _ -> Error (`Parse_json_error body)

let run body = decode body

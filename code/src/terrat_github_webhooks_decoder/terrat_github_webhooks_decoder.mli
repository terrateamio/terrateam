type err =
  [ `Parse_json_error of string
  | `Bad_signature of string * string
  | `Missing_signature
  | `Missing_event_type
  | `Unknown_action of string
  ]
[@@deriving show]

val run :
  ?secret:string -> Cohttp.Header.t -> string -> (Terrat_github_webhooks.Event.t, [> err ]) result

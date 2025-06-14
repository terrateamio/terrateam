type err = [ `Parse_json_error of string ] [@@deriving show]

val run : string -> (Gitlab_webhooks.Event.t, [> err ]) result

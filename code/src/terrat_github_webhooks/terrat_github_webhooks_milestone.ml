module State = struct
  let t_of_yojson = function
    | `String "closed" -> Ok `Closed
    | `String "open" -> Ok `Open
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Closed -> `String "closed"
    | `Open -> `String "open"

  type t =
    ([ `Closed
     | `Open
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  closed_at : string option; [@default None]
  closed_issues : int;
  created_at : string;
  creator : Terrat_github_webhooks_user.t;
  description : string option; [@default None]
  due_on : string option; [@default None]
  html_url : string;
  id : int;
  labels_url : string;
  node_id : string;
  number : int;
  open_issues : int;
  state : State.t;
  title : string;
  updated_at : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

module State = struct
  let t_of_yojson = function
    | `String "open" -> Ok "open"
    | `String "closed" -> Ok "closed"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  closed_at : string option;
  closed_issues : int;
  created_at : string;
  creator : Terrat_github_webhooks_user.t;
  description : string option;
  due_on : string option;
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
[@@deriving yojson { strict = false; meta = true }, make, show]

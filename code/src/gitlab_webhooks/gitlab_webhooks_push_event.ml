module Event_name = struct
  let t_of_yojson = function
    | `String "push" -> Ok "push"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_kind = struct
  let t_of_yojson = function
    | `String "push" -> Ok "push"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  checkout_sha : string;
  event_name : Event_name.t;
  object_kind : Object_kind.t;
  project : Gitlab_webhooks_project.t;
  project_id : int;
  ref_ : string; [@key "ref"]
  repository : Gitlab_webhooks_repository.t;
  user_username : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

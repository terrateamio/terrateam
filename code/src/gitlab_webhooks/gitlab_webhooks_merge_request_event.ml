module Event_type = struct
  let t_of_yojson = function
    | `String "merge_request" -> Ok "merge_request"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_attributes = struct
  module Action = struct
    let t_of_yojson = function
      | `String "approval" -> Ok "approval"
      | `String "approved" -> Ok "approved"
      | `String "close" -> Ok "close"
      | `String "merge" -> Ok "merge"
      | `String "open" -> Ok "open"
      | `String "reopen" -> Ok "reopen"
      | `String "unapproval" -> Ok "unapproval"
      | `String "unapproved" -> Ok "unapproved"
      | `String "update" -> Ok "update"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    id : int;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Object_kind = struct
  let t_of_yojson = function
    | `String "merge_request" -> Ok "merge_request"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  event_type : Event_type.t option; [@default None]
  object_attributes : Object_attributes.t option; [@default None]
  object_kind : Object_kind.t option; [@default None]
  project : Gitlab_webhooks_project.t option; [@default None]
  repository : Gitlab_webhooks_repository.t option; [@default None]
  user : Gitlab_webhooks_user.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

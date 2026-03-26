module Event_type = struct
  let t_of_yojson = function
    | `String "note" -> Ok `Note
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Note -> `String "note"

  type t = ([ `Note ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_attributes = struct
  module Action = struct
    let t_of_yojson = function
      | `String "create" -> Ok `Create
      | `String "update" -> Ok `Update
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Create -> `String "create"
      | `Update -> `String "update"

    type t =
      ([ `Create
       | `Update
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t option; [@default None]
    created_at : string option; [@default None]
    id : int option; [@default None]
    note : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Object_kind = struct
  let t_of_yojson = function
    | `String "note" -> Ok `Note
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Note -> `String "note"

  type t = ([ `Note ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  event_type : Event_type.t;
  merge_request : Gitlab_webhooks_merge_request.t;
  object_attributes : Object_attributes.t;
  object_kind : Object_kind.t;
  project : Gitlab_webhooks_project.t;
  project_id : int;
  repository : Gitlab_webhooks_repository.t;
  user : Gitlab_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

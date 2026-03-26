module Event_type = struct
  let t_of_yojson = function
    | `String "merge_request" -> Ok `Merge_request
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Merge_request -> `String "merge_request"

  type t = ([ `Merge_request ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Object_attributes = struct
  module Action = struct
    let t_of_yojson = function
      | `String "approval" -> Ok `Approval
      | `String "approved" -> Ok `Approved
      | `String "close" -> Ok `Close
      | `String "merge" -> Ok `Merge
      | `String "open" -> Ok `Open
      | `String "reopen" -> Ok `Reopen
      | `String "unapproval" -> Ok `Unapproval
      | `String "unapproved" -> Ok `Unapproved
      | `String "update" -> Ok `Update
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Approval -> `String "approval"
      | `Approved -> `String "approved"
      | `Close -> `String "close"
      | `Merge -> `String "merge"
      | `Open -> `String "open"
      | `Reopen -> `String "reopen"
      | `Unapproval -> `String "unapproval"
      | `Unapproved -> `String "unapproved"
      | `Update -> `String "update"

    type t =
      ([ `Approval
       | `Approved
       | `Close
       | `Merge
       | `Open
       | `Reopen
       | `Unapproval
       | `Unapproved
       | `Update
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    action : Action.t;
    id : int;
    iid : int;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Object_kind = struct
  let t_of_yojson = function
    | `String "merge_request" -> Ok `Merge_request
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Merge_request -> `String "merge_request"

  type t = ([ `Merge_request ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  event_type : Event_type.t;
  object_attributes : Object_attributes.t;
  object_kind : Object_kind.t;
  project : Gitlab_webhooks_project.t;
  repository : Gitlab_webhooks_repository.t;
  user : Gitlab_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

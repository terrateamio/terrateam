module Object_attributes = struct
  module Stages = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    created_at : string;
    finished_at : string option; [@default None]
    id : int;
    iid : int;
    ref_ : string; [@key "ref"]
    source : string option; [@default None]
    stages : Stages.t;
    status : string;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show, eq]
end

module Object_kind = struct
  let t_of_yojson = function
    | `String "pipeline" -> Ok "pipeline"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  merge_request : Gitlab_webhooks_merge_request.t option; [@default None]
  object_attributes : Object_attributes.t;
  object_kind : Object_kind.t;
  project : Gitlab_webhooks_project.t;
  user : Gitlab_webhooks_user.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

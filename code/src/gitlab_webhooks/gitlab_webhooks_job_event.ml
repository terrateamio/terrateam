module Object_kind = struct
  let t_of_yojson = function
    | `String "build" -> Ok "build"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  build_id : int;
  build_name : string;
  build_stage : string;
  build_status : string;
  object_kind : Object_kind.t;
  project : Gitlab_webhooks_project.t;
  project_id : int option; [@default None]
  project_name : string option; [@default None]
  ref_ : string; [@key "ref"]
  repository : Gitlab_webhooks_repository.t option; [@default None]
  sha : string;
  user : Gitlab_webhooks_user.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]

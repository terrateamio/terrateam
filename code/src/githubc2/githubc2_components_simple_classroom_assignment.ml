module Primary = struct
  module Type = struct
    let t_of_yojson = function
      | `String "individual" -> Ok "individual"
      | `String "group" -> Ok "group"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    accepted : int;
    classroom : Githubc2_components_simple_classroom.t;
    deadline : string option;
    editor : string;
    feedback_pull_requests_enabled : bool;
    id : int;
    invitations_enabled : bool;
    invite_link : string;
    language : string;
    max_members : int option; [@default None]
    max_teams : int option; [@default None]
    passing : int;
    public_repo : bool;
    slug : string;
    students_are_repo_admins : bool;
    submitted : int;
    title : string;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

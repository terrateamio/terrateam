module Primary = struct
  module Project_card_ = struct
    module Primary = struct
      type t = {
        column_name : string;
        id : int;
        previous_column_name : string option; [@default None]
        project_id : int;
        project_url : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Githubc2_components_simple_user.t;
    commit_id : string option;
    commit_url : string option;
    created_at : string;
    event : string;
    id : int;
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option;
    project_card : Project_card_.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

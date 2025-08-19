module Primary = struct
  module Rename = struct
    module Primary = struct
      type t = {
        from : string;
        to_ : string; [@key "to"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Githubc2_components_simple_user.t;
    commit_id : string option; [@default None]
    commit_url : string option; [@default None]
    created_at : string;
    event : string;
    id : int;
    node_id : string;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    rename : Rename.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

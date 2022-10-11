module Primary = struct
  module Merge_group = struct
    module Primary = struct
      type t = {
        base_ref : string;
        head_ref : string;
        head_sha : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    action : string;
    installation : Githubc2_components_simple_installation.t option; [@default None]
    merge_group : Merge_group.t;
    organization : Githubc2_components_organization_simple.t option; [@default None]
    repository : Githubc2_components_repository.t option; [@default None]
    sender : Githubc2_components_simple_user.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

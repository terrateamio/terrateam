module Primary = struct
  module Commit_ = struct
    module Primary = struct
      type t = {
        sha : string;
        url : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    commit : Commit_.t;
    name : string;
    protected : bool;
    protection : Githubc2_components_branch_protection.t option; [@default None]
    protection_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

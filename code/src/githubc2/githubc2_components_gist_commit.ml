module Primary = struct
  module Change_status = struct
    module Primary = struct
      type t = {
        additions : int option; [@default None]
        deletions : int option; [@default None]
        total : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    change_status : Change_status.t;
    committed_at : string;
    url : string;
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
    version : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

module Primary = struct
  module Change_status = struct
    module Primary = struct
      type t = {
        additions : int option; [@default None]
        deletions : int option; [@default None]
        total : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    change_status : Change_status.t option; [@default None]
    committed_at : string option; [@default None]
    url : string option; [@default None]
    user : Githubc2_components_nullable_simple_user.t option; [@default None]
    version : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

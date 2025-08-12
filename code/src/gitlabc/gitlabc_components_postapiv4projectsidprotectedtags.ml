module Allowed_to_create = struct
  module Items = struct
    module Primary = struct
      type t = {
        access_level : int option; [@default None]
        deploy_key_id : int option; [@default None]
        group_id : int option; [@default None]
        user_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  allowed_to_create : Allowed_to_create.t option; [@default None]
  create_access_level : int option; [@default None]
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

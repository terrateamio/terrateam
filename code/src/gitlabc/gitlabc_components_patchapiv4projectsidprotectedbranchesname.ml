module Allowed_to_merge = struct
  module Items = struct
    module Primary = struct
      type t = {
        destroy_ : bool option; [@default None] [@key "_destroy"]
        access_level : int option; [@default None]
        group_id : int option; [@default None]
        id : int option; [@default None]
        user_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Allowed_to_push = struct
  module Items = struct
    module Primary = struct
      type t = {
        destroy_ : bool option; [@default None] [@key "_destroy"]
        access_level : int option; [@default None]
        deploy_key_id : int option; [@default None]
        group_id : int option; [@default None]
        id : int option; [@default None]
        user_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Allowed_to_unprotect = struct
  module Items = struct
    module Primary = struct
      type t = {
        destroy_ : bool option; [@default None] [@key "_destroy"]
        access_level : int option; [@default None]
        group_id : int option; [@default None]
        id : int option; [@default None]
        user_id : int option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  allow_force_push : bool option; [@default None]
  allowed_to_merge : Allowed_to_merge.t option; [@default None]
  allowed_to_push : Allowed_to_push.t option; [@default None]
  allowed_to_unprotect : Allowed_to_unprotect.t option; [@default None]
  code_owner_approval_required : bool option; [@default None]
  unprotect_access_level : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

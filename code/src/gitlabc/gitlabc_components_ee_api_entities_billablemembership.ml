module Primary = struct
  module Access_level = struct
    module Primary = struct
      type t = {
        custom_role : string option; [@default None]
        integer_value : string option; [@default None]
        string_value : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    access_level : Access_level.t option; [@default None]
    created_at : string option; [@default None]
    expires_at : string option; [@default None]
    id : string option; [@default None]
    source_full_name : string option; [@default None]
    source_id : string option; [@default None]
    source_members_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

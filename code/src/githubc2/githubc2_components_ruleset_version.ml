module Primary = struct
  module Actor_ = struct
    module Primary = struct
      type t = {
        id : int option; [@default None]
        type_ : string option; [@default None] [@key "type"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    actor : Actor_.t;
    updated_at : string;
    version_id : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

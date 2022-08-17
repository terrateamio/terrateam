module Primary = struct
  module Actions_caches = struct
    module Items = struct
      module Primary = struct
        type t = {
          created_at : string option; [@default None]
          id : int option; [@default None]
          key : string option; [@default None]
          last_accessed_at : string option; [@default None]
          ref_ : string option; [@default None] [@key "ref"]
          size_in_bytes : int option; [@default None]
          version : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    actions_caches : Actions_caches.t;
    total_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

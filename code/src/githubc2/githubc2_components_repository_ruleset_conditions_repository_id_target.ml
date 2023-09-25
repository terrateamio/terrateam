module Primary = struct
  module Repository_id = struct
    module Primary = struct
      module Repository_ids = struct
        type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = { repository_ids : Repository_ids.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { repository_id : Repository_id.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

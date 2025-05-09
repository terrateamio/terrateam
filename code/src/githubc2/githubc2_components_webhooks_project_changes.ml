module Primary = struct
  module Archived_at = struct
    module Primary = struct
      type t = {
        from : string option; [@default None]
        to_ : string option; [@default None] [@key "to"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { archived_at : Archived_at.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

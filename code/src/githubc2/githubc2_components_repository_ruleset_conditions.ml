module Primary = struct
  module Ref_name = struct
    module Primary = struct
      module Exclude = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Include = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        exclude : Exclude.t option; [@default None]
        include_ : Include.t option; [@default None] [@key "include"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = { ref_name : Ref_name.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

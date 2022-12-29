module Primary = struct
  module Names = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { names : Names.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

module Primary = struct
  module Include_claim_keys = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = { include_claim_keys : Include_claim_keys.t }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

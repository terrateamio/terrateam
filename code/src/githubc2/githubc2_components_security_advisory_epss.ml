module Primary = struct
  type t = {
    percentage : float option; [@default None]
    percentile : float option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

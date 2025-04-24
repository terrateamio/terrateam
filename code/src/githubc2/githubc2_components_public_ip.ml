module Primary = struct
  type t = {
    enabled : bool option; [@default None]
    length : int option; [@default None]
    prefix : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

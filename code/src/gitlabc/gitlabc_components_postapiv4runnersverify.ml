module Primary = struct
  type t = {
    system_id : string option; [@default None]
    token : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

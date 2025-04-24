module Primary = struct
  type t = {
    color : string option; [@default None]
    description : string option; [@default None]
    id : string;
    name : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

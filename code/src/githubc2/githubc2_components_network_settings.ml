module Primary = struct
  type t = {
    id : string;
    name : string;
    network_configuration_id : string option; [@default None]
    region : string;
    subnet_id : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

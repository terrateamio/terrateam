module Primary = struct
  type t = {
    image_url : string;
    link_url : string;
    name : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

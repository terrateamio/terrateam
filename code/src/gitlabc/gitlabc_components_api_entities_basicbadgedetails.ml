module Primary = struct
  type t = {
    image_url : string option; [@default None]
    link_url : string option; [@default None]
    name : string option; [@default None]
    rendered_image_url : string option; [@default None]
    rendered_link_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

module Primary = struct
  type t = {
    avatar_url : string;
    created_at : string option;
    description : string option; [@default None]
    html_url : string;
    id : int;
    name : string;
    node_id : string;
    slug : string;
    updated_at : string option;
    website_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

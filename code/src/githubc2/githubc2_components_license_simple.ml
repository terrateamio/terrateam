module Primary = struct
  type t = {
    html_url : string option; [@default None]
    key : string;
    name : string;
    node_id : string;
    spdx_id : string option; [@default None]
    url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

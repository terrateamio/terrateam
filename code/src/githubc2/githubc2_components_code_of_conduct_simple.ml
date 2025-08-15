module Primary = struct
  type t = {
    html_url : string option; [@default None]
    key : string;
    name : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

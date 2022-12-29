module Primary = struct
  type t = {
    page_url : string;
    preview_url : string option; [@default None]
    status_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

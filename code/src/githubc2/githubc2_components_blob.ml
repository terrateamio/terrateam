module Primary = struct
  type t = {
    content : string;
    encoding : string;
    highlighted_content : string option; [@default None]
    node_id : string;
    sha : string;
    size : int option;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

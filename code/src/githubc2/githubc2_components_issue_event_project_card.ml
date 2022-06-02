module Primary = struct
  type t = {
    column_name : string;
    id : int;
    previous_column_name : string option; [@default None]
    project_id : int;
    project_url : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

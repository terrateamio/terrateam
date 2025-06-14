module Primary = struct
  type t = {
    password : string;
    project_name : string;
    url : string;
    use_inherited_settings : bool option; [@default None]
    username : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

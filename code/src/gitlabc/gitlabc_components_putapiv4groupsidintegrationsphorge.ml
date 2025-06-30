module Primary = struct
  type t = {
    issues_url : string;
    project_url : string;
    push_events : bool option; [@default None]
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

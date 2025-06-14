module Primary = struct
  type t = {
    confidential_issues_events : bool option; [@default None]
    issues_events : bool option; [@default None]
    token : string option; [@default None]
    url : string;
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

module Primary = struct
  type t = {
    enable_ssl_verification : bool option; [@default None]
    jenkins_url : string;
    merge_requests_events : bool option; [@default None]
    password : string option; [@default None]
    project_name : string;
    push_events : bool option; [@default None]
    tag_push_events : bool option; [@default None]
    use_inherited_settings : bool option; [@default None]
    username : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

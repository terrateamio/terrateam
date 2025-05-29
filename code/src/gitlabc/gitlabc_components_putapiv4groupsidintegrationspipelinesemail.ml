module Primary = struct
  type t = {
    branches_to_be_notified : string option; [@default None]
    notify_only_broken_pipelines : bool option; [@default None]
    notify_only_default_branch : bool option; [@default None]
    pipeline_events : bool option; [@default None]
    recipients : string;
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

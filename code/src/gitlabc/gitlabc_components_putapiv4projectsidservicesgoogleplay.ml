module Primary = struct
  type t = {
    google_play_protected_refs : bool option; [@default None]
    package_name : string;
    service_account_key : string;
    service_account_key_file_name : string;
    use_inherited_settings : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

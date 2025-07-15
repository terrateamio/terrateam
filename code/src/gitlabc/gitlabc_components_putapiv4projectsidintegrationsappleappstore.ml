type t = {
  app_store_issuer_id : string;
  app_store_key_id : string;
  app_store_private_key : string;
  app_store_private_key_file_name : string;
  app_store_protected_refs : bool option; [@default None]
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

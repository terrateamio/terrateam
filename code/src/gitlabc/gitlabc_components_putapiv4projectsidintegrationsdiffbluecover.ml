type t = {
  diffblue_access_token_name : string;
  diffblue_access_token_secret : string;
  diffblue_license_key : string;
  use_inherited_settings : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

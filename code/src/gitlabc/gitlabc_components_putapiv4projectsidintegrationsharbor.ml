type t = {
  password : string;
  project_name : string;
  url : string;
  use_inherited_settings : bool option; [@default None]
  username : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

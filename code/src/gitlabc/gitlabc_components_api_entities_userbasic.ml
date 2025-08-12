type t = {
  avatar_path : string option; [@default None]
  avatar_url : string option; [@default None]
  id : int;
  locked : bool option; [@default None]
  name : string option; [@default None]
  state : string;
  username : string;
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

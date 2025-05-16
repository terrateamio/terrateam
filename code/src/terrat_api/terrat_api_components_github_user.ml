type t = {
  avatar_url : string option; [@default None]
  username : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  avatar_url : string option; [@default None]
  username : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

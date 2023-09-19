type t = {
  avatar_url : string option; [@default None]
  email : string option; [@default None]
  id : string;
  name : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

type t = {
  avatar_url : string option; [@default None]
  created_at : string;
  email : string option; [@default None]
  id : int;
  name : string option; [@default None]
  public_email : string option; [@default None]
  state : string option; [@default None]
  username : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

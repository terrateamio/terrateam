type t = {
  confidential : bool; [@default true]
  name : string;
  redirect_uri : string;
  scopes : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

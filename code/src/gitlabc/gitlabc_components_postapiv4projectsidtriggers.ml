type t = {
  description : string;
  expires_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

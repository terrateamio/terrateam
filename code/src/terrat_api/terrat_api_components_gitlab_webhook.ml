type t = {
  state : string;
  webhook_secret : string option; [@default None]
  webhook_url : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  system_id : string option; [@default None]
  token : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

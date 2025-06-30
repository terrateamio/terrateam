type t = {
  base_sha : string;
  head_sha : string;
  start_sha : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

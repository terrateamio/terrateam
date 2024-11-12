type t = {
  pull_number : int;
  pull_request_title : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

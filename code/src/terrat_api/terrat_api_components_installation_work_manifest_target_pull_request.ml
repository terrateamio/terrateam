type t = {
  pull_number : int;
  pull_request_title : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

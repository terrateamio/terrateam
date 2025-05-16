type t = {
  path : string;
  rank : int;
  workflow : int option; [@default None]
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

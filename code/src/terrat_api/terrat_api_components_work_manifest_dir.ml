type t = {
  path : string;
  rank : int;
  workflow : int option; [@default None]
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

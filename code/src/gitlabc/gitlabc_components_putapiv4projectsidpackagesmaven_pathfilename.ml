type t = {
  file : string;
  path : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

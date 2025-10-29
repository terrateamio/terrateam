type t = {
  dir : string;
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

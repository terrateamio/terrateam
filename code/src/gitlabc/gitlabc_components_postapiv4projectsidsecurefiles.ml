type t = {
  file : string;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

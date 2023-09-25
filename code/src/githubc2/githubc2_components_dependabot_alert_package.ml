type t = {
  ecosystem : string;
  name : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

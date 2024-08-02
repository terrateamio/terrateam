type t = {
  ecosystem : string;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

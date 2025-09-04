type t = {
  key : string;
  title : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

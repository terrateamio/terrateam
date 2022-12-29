type t = {
  run_id : string;
  sha : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

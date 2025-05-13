type t = {
  run_id : string;
  sha : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

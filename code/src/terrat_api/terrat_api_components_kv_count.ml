type t = {
  count : int;
  max_idx : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

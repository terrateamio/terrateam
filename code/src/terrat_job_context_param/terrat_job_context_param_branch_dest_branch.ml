type t = {
  branch : string;
  dest_branch : string;
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]

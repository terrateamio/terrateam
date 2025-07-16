type t = {
  branch : string;
  ref_ : string; [@key "ref"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

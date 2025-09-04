type t = {
  message : string option; [@default None]
  ref_ : string; [@key "ref"]
  tag_name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

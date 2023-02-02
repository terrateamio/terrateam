type t = {
  has_changes : bool; [@default true]
  plan : string;
  plan_text : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

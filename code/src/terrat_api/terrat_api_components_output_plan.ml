type t = {
  has_changes : bool; [@default true]
  plan : string;
  plan_text : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  has_changes : bool; [@default true]
  path : string;
  plan_data : string;
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  path : string;
  plan_data : string;
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

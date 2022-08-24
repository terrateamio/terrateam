type t = {
  plan : string;
  plan_text : string;
}
[@@deriving yojson { strict = true; meta = true }, show]

type t = {
  id : string;
  installation_id : string;
  name : string;
  updated_at : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

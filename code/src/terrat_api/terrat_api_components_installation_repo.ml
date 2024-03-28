type t = {
  id : string;
  installation_id : string;
  name : string;
  setup : bool;
  updated_at : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

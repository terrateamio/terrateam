type t = {
  data : string option; [@default None]
  id : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  description : string option; [@default None]
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

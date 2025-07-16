type t = {
  component : string;
  distribution : string option; [@default None]
  file : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

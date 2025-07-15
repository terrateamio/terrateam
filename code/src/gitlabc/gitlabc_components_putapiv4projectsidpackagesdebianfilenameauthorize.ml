type t = {
  component : string;
  distribution : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  output_key : string option; [@default None]
  text : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

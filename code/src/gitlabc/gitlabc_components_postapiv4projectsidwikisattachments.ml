type t = {
  branch : string option; [@default None]
  file : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

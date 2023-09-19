type t = {
  dir : string;
  success : bool option; [@default None]
  workspace : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]

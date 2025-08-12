type t = {
  dir : string;
  success : bool option; [@default None]
  workspace : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  alt : string option; [@default None]
  full_path : string option; [@default None]
  id : string option; [@default None]
  markdown : string option; [@default None]
  url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

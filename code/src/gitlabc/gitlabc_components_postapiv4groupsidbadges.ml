type t = {
  image_url : string;
  link_url : string;
  name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

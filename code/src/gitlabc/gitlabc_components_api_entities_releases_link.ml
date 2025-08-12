type t = {
  direct_asset_url : string option; [@default None]
  id : int option; [@default None]
  link_type : string option; [@default None]
  name : string option; [@default None]
  url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  api_token : string;
  api_url : string option; [@default None]
  url : string;
  use_inherited_settings : bool option; [@default None]
  zentao_product_xid : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

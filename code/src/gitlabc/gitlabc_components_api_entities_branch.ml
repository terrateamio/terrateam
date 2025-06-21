type t = {
  can_push : bool option; [@default None]
  commit : Gitlabc_components_api_entities_commit.t;
  default : bool;
  developers_can_merge : bool option; [@default None]
  developers_can_push : bool option; [@default None]
  merged : bool;
  name : string;
  protected : bool option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

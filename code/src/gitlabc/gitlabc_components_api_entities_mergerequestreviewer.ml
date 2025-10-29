type t = {
  created_at : string option; [@default None]
  state : string;
  user : Gitlabc_components_api_entities_userbasic.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

type t = {
  approved : bool option; [@default None]
  approved_by : Gitlabc_components_api_entities_approvals.t option; [@default None]
  user_can_approve : bool option; [@default None]
  user_has_approved : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

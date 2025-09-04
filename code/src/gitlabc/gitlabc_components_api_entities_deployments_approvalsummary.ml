type t = {
  rules : Gitlabc_components_api_entities_protectedenvironments_approvalruleforsummary.t option;
      [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

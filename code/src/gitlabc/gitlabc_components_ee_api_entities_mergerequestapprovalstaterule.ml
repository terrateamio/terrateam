module Primary = struct
  module Approved_by = struct
    type t = Gitlabc_components_api_entities_userbasic.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Eligible_approvers = struct
    type t = Gitlabc_components_api_entities_userbasic.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Groups = struct
    type t = Gitlabc_components_api_entities_group.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Users = struct
    type t = Gitlabc_components_api_entities_userbasic.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    approvals_required : int option; [@default None]
    approved : bool option; [@default None]
    approved_by : Approved_by.t option; [@default None]
    code_owner : bool option; [@default None]
    contains_hidden_groups : bool option; [@default None]
    eligible_approvers : Eligible_approvers.t option; [@default None]
    groups : Groups.t option; [@default None]
    id : int option; [@default None]
    name : string option; [@default None]
    overridden : bool option; [@default None]
    report_type : string option; [@default None]
    rule_type : string option; [@default None]
    section : string option; [@default None]
    source_rule : Gitlabc_components_ee_api_entities_mergerequestapprovalrule_sourcerule.t option;
        [@default None]
    users : Users.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

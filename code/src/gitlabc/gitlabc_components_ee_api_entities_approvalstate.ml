module Primary = struct
  module Approval_rules_left = struct
    type t = Gitlabc_components_ee_api_entities_approvalruleshort.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Approved_by = struct
    type t = Gitlabc_components_api_entities_approvals.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Invalid_approvers_rules = struct
    type t = Gitlabc_components_ee_api_entities_approvalruleshort.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Suggested_approvers = struct
    type t = Gitlabc_components_api_entities_userbasic.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    approval_rules_left : Approval_rules_left.t option; [@default None]
    approvals_left : int option; [@default None]
    approvals_required : int option; [@default None]
    approved : bool option; [@default None]
    approved_by : Approved_by.t option; [@default None]
    approver_groups : string option; [@default None]
    approvers : string option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    has_approval_rules : bool option; [@default None]
    id : int option; [@default None]
    iid : int option; [@default None]
    invalid_approvers_rules : Invalid_approvers_rules.t option; [@default None]
    merge_request_approvers_available : bool option; [@default None]
    merge_status : string option; [@default None]
    multiple_approval_rules_available : bool option; [@default None]
    project_id : int option; [@default None]
    require_password_to_approve : bool option; [@default None]
    state : string option; [@default None]
    suggested_approvers : Suggested_approvers.t option; [@default None]
    title : string option; [@default None]
    updated_at : string option; [@default None]
    user_can_approve : bool option; [@default None]
    user_has_approved : bool option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

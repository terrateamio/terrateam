module Primary = struct
  module Add_labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Assignee_ids = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Remove_labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Reviewer_ids = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    add_labels : Add_labels.t option; [@default None]
    allow_collaboration : bool option; [@default None]
    allow_maintainer_to_push : bool option; [@default None]
    approvals_before_merge : int option; [@default None]
    assignee_id : int option; [@default None]
    assignee_ids : Assignee_ids.t option; [@default None]
    description : string option; [@default None]
    labels : Labels.t option; [@default None]
    merge_after : string option; [@default None]
    milestone_id : int option; [@default None]
    remove_labels : Remove_labels.t option; [@default None]
    remove_source_branch : bool option; [@default None]
    reviewer_ids : Reviewer_ids.t option; [@default None]
    source_branch : string;
    squash : bool option; [@default None]
    target_branch : string;
    target_project_id : int option; [@default None]
    title : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

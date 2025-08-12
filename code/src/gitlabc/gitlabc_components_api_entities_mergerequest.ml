module Assignees = struct
  type t = Gitlabc_components_api_entities_userbasic.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Labels = struct
  module Items = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Reviewers = struct
  type t = Gitlabc_components_api_entities_userbasic.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module User = struct
  module Primary = struct
    type t = { can_merge : bool option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  assignee : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  assignees : Assignees.t option; [@default None]
  author : Gitlabc_components_api_entities_userbasic.t;
  closed_at : string option; [@default None]
  closed_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  created_at : string;
  description : string option; [@default None]
  detailed_merge_status : string option; [@default None]
  diff_refs : Gitlabc_components_api_entities_diffrefs.t option; [@default None]
  draft : bool option; [@default None]
  has_conflicts : bool option; [@default None]
  id : int;
  iid : int;
  labels : Labels.t option; [@default None]
  merge_commit_sha : string option; [@default None]
  merge_error : string option; [@default None]
  merge_status : string option; [@default None]
  merge_user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  merged_at : string option; [@default None]
  merged_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  project_id : int;
  reference : string option; [@default None]
  reviewers : Reviewers.t option; [@default None]
  sha : string option; [@default None]
  source_branch : string;
  state : string;
  target_branch : string;
  target_project_id : int option; [@default None]
  title : string;
  updated_at : string option; [@default None]
  user : User.t;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

module Labels = struct
  module Items = struct
    type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module User = struct
  module Primary = struct
    type t = { can_merge : string option [@default None] }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = {
  allow_collaboration : string option; [@default None]
  allow_maintainer_to_push : string option; [@default None]
  approvals_before_merge : int option; [@default None]
  assignee : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  assignees : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  author : Gitlabc_components_api_entities_userbasic.t;
  blocking_discussions_resolved : bool option; [@default None]
  changes_count : string option; [@default None]
  closed_at : string option; [@default None]
  closed_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  created_at : string;
  description : string option; [@default None]
  description_html : string option; [@default None]
  detailed_merge_status : string option; [@default None]
  diff_refs : Gitlabc_components_api_entities_diffrefs.t option; [@default None]
  discussion_locked : string option; [@default None]
  diverged_commits_count : string option; [@default None]
  downvotes : string option; [@default None]
  draft : bool option; [@default None]
  first_contribution : bool option; [@default None]
  first_deployed_to_production_at : string option; [@default None]
  force_remove_source_branch : bool option; [@default None]
  has_conflicts : bool option; [@default None]
  head_pipeline : Gitlabc_components_api_entities_ci_pipeline.t option; [@default None]
  id : int;
  iid : int;
  imported : string option; [@default None]
  imported_from : string option; [@default None]
  labels : Labels.t option; [@default None]
  latest_build_finished_at : string option; [@default None]
  latest_build_started_at : string option; [@default None]
  merge_after : string option; [@default None]
  merge_commit_sha : string option; [@default None]
  merge_error : string option; [@default None]
  merge_status : string option; [@default None]
  merge_user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  merge_when_pipeline_succeeds : bool option; [@default None]
  merged_at : string option; [@default None]
  merged_by : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  milestone : Gitlabc_components_api_entities_milestone.t option; [@default None]
  pipeline : Gitlabc_components_api_entities_ci_pipelinebasic.t option; [@default None]
  prepared_at : string option; [@default None]
  project_id : int;
  rebase_in_progress : string option; [@default None]
  reference : string option; [@default None]
  references : Gitlabc_components_api_entities_issuablereferences.t option; [@default None]
  reviewers : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  sha : string;
  should_remove_source_branch : bool option; [@default None]
  source_branch : string;
  source_project_id : string option; [@default None]
  squash : string option; [@default None]
  squash_commit_sha : string option; [@default None]
  squash_on_merge : string option; [@default None]
  state : string;
  subscribed : bool option; [@default None]
  target_branch : string;
  target_project_id : string option; [@default None]
  task_completion_status : string option; [@default None]
  time_stats : Gitlabc_components_api_entities_issuabletimestats.t option; [@default None]
  title : string;
  title_html : string option; [@default None]
  updated_at : string option; [@default None]
  upvotes : string option; [@default None]
  user : User.t;
  user_notes_count : string option; [@default None]
  web_url : string option; [@default None]
  work_in_progress : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

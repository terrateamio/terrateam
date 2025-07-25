module P2 = Terrat_vcs_provider2

module Make (S : Terrat_vcs_provider2.S) = struct
  module Hmap = Hmap.Make (struct
    type 'a t = string
  end)

  let account : S.Api.Account.t Hmap.key = Hmap.Key.create "account"
  let account_status : P2.Account_status.t Hmap.key = Hmap.Key.create "account_status"
  let branch_name : S.Api.Ref.t Hmap.key = Hmap.Key.create "branch_name"
  let dest_branch_name : S.Api.Ref.t Hmap.key = Hmap.Key.create "dest_branch_name"
  let branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "branch_ref"
  let dest_branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "dest_branch_ref"
  let client : S.Api.Client.t Hmap.key = Hmap.Key.create "client"
  let repo_tree_dest_branch : string list Hmap.key = Hmap.Key.create "repo_tree_dest_branch"
  let repo_tree_branch : string list Hmap.key = Hmap.Key.create "repo_tree_branch"

  let repo_config_system_defaults :
      Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t Hmap.key =
    Hmap.Key.create "repo_config_system_defaults"

  let repo_config_raw :
      (string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_raw"

  let repo_config_with_provenance :
      (string list * Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t) Hmap.key =
    Hmap.Key.create "repo_config_with_provenance"

  let repo_config : Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t Hmap.key =
    Hmap.Key.create "repo_config"

  let publish_repo_config : unit Hmap.key = Hmap.Key.create "publish_repo_config"
  let comment_id : int Hmap.key = Hmap.Key.create "comment_id"
  let pull_request_id : S.Api.Pull_request.Id.t Hmap.key = Hmap.Key.create "pull_request_id"

  let pull_request : (Terrat_change.Diff.t list, bool) S.Api.Pull_request.t Hmap.key =
    Hmap.Key.create "pull_request"

  let user : S.Api.User.t Hmap.key = Hmap.Key.create "user"
  let repo : S.Api.Repo.t Hmap.key = Hmap.Key.create "repo"
  let react_to_comment : unit Hmap.key = Hmap.Key.create "react_to_comment"
  let encryption_key : Cstruct.t Hmap.key = Hmap.Key.create "encryption_key"

  let job_work_manifests :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      list
      Hmap.key =
    Hmap.Key.create "job_work_manifests"

  let default_branch_sha : S.Api.Ref.t Hmap.key = Hmap.Key.create "default_branch_sha"
  let working_branch_ref : S.Api.Ref.t Hmap.key = Hmap.Key.create "working_branch_ref"
  let work_manifest_id : Uuidm.t option Hmap.key = Hmap.Key.create "work_manifest_id"

  let work_manifest :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "work_manifest"

  (* Repo tree build targets *)
  let repo_tree_wm_completed :
      ( S.Api.Account.t,
        ((unit, unit) S.Api.Pull_request.t, S.Api.Repo.t) Terrat_vcs_provider2.Target.t )
      Terrat_work_manifest3.Existing.t
      Hmap.key =
    Hmap.Key.create "repo_tree_wm_completed"

  let built_repo_tree_branch : string list Hmap.key = Hmap.Key.create "built_repo_tree_branch"

  (* Context management *)
  let store_repository : unit Hmap.key = Hmap.Key.create "store_repository"
  let store_pull_request : unit Hmap.key = Hmap.Key.create "store_pull_request"
  let tag_query : Terrat_tag_query.t Hmap.key = Hmap.Key.create "tag_query"

  let context : (S.Api.Pull_request.Id.t, S.Api.Ref.t) Terrat_job_context.Context.t Hmap.key =
    Hmap.Key.create "context"

  let job :
      (S.Api.Pull_request.Id.t, S.Api.Ref.t, S.Api.User.t option) Terrat_job_context.Job.t Hmap.key
      =
    Hmap.Key.create "job"

  (* API facing targets *)
  let update_context_for_pull_request : unit Hmap.key =
    Hmap.Key.create "update_context_for_pull_request"

  let eval_job : unit Hmap.key = Hmap.Key.create "eval_job"
end

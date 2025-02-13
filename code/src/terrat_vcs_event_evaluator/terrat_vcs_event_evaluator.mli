module Make (S : Terrat_vcs_provider2.S) : sig
  module Repo_config : sig
    type fetch_err = Terratc_intf.Repo_config.fetch_err [@@deriving show]
  end

  module State : Abb_flow.S
  module Id : Abb_flow.ID

  module Event : sig
    type t =
      | Pull_request_open of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_close of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_sync of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_ready_for_review of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          pull_request_id : int;
        }
      | Pull_request_comment of {
          account : S.Account.t;
          comment : Terrat_comment.t;
          repo : S.Repo.t;
          pull_request_id : int;
          comment_id : int;
          user : S.User.t;
        }
      | Push of {
          account : S.Account.t;
          user : S.User.t;
          repo : S.Repo.t;
          branch : S.Ref.t;
        }
      | Run_scheduled_drift
      | Run_drift of {
          account : S.Account.t;
          repo : S.Repo.t;
          reconcile : bool option;
          tag_query : Terrat_tag_query.t option;
        }
  end

  module Flow : module type of Abb_flow.Make (Abb.Future) (Id) (State)

  val run_event : Terrat_storage.t Terrat_vcs_provider.Ctx.t -> Event.t -> unit Abb.Future.t

  val run_work_manifest_initiate :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t ->
    Cstruct.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_initiate.t ->
    (Terrat_api_components.Work_manifest.t option, [> `Error ]) result Abb.Future.t

  val run_work_manifest_result :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_plan_store :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t ->
    Uuidm.t ->
    Terrat_api_components.Plan_create.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_plan_fetch :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    (string option, [> `Error ]) result Abb.Future.t

  (** Signal that the work manifest failed for OOB reasons. *)
  val run_work_manifest_failure :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

  val run_scheduled_drift :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t -> (unit, [> `Error ]) result Abb.Future.t

  val run_plan_cleanup :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t -> (unit, [> `Error ]) result Abb.Future.t

  val run_flow_state_cleanup :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t -> (unit, [> `Error ]) result Abb.Future.t

  val run_repo_config_cleanup :
    Terrat_storage.t Terrat_vcs_provider.Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
end

module Make (S : Terrat_vcs_provider2.S) : sig
  module Ctx : sig
    type 's t

    val make : request_id:string -> config:S.Api.Config.t -> storage:'s -> unit -> 's t
    val request_id : 's t -> string
    val config : 's t -> S.Api.Config.t
    val storage : 's t -> 's
    val set_request_id : string -> 's t -> 's t
    val set_storage : 's -> 'a t -> 's t
  end

  module Repo_config : sig
    type fetch_err = Terrat_vcs_provider2.fetch_repo_config_with_provenance_err [@@deriving show]
  end

  module State : Abb_flow.S
  module Id : Abb_flow.ID

  module Event : sig
    type t =
      | Pull_request_open of {
          account : S.Api.Account.t;
          user : S.Api.User.t;
          repo : S.Api.Repo.t;
          pull_request_id : S.Api.Pull_request.Id.t;
        }
      | Pull_request_close of {
          account : S.Api.Account.t;
          user : S.Api.User.t;
          repo : S.Api.Repo.t;
          pull_request_id : S.Api.Pull_request.Id.t;
        }
      | Pull_request_sync of {
          account : S.Api.Account.t;
          user : S.Api.User.t;
          repo : S.Api.Repo.t;
          pull_request_id : S.Api.Pull_request.Id.t;
        }
      | Pull_request_ready_for_review of {
          account : S.Api.Account.t;
          user : S.Api.User.t;
          repo : S.Api.Repo.t;
          pull_request_id : S.Api.Pull_request.Id.t;
        }
      | Pull_request_comment of {
          account : S.Api.Account.t;
          comment : Terrat_comment.t;
          repo : S.Api.Repo.t;
          pull_request_id : S.Api.Pull_request.Id.t;
          comment_id : int;
          user : S.Api.User.t;
        }
      | Push of {
          account : S.Api.Account.t;
          user : S.Api.User.t;
          repo : S.Api.Repo.t;
          branch : S.Api.Ref.t;
        }
      | Run_scheduled_drift
      | Run_drift of {
          account : S.Api.Account.t;
          repo : S.Api.Repo.t;
          reconcile : bool option;
          tag_query : Terrat_tag_query.t option;
        }
  end

  module Flow : module type of Abb_flow.Make (Abb.Future) (Id) (State)

  val run_event : Terrat_storage.t Ctx.t -> Event.t -> unit Abb.Future.t

  val run_pull_request_open :
    ctx:Terrat_storage.t Ctx.t ->
    account:S.Api.Account.t ->
    user:S.Api.User.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    unit ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_pull_request_close :
    ctx:Terrat_storage.t Ctx.t ->
    account:S.Api.Account.t ->
    user:S.Api.User.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    unit ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_pull_request_sync :
    ctx:Terrat_storage.t Ctx.t ->
    account:S.Api.Account.t ->
    user:S.Api.User.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    unit ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_pull_request_ready_for_review :
    ctx:Terrat_storage.t Ctx.t ->
    account:S.Api.Account.t ->
    user:S.Api.User.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    unit ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_pull_request_comment :
    ctx:Terrat_storage.t Ctx.t ->
    account:S.Api.Account.t ->
    user:S.Api.User.t ->
    comment:Terrat_comment.t ->
    repo:S.Api.Repo.t ->
    pull_request_id:S.Api.Pull_request.Id.t ->
    comment_id:int ->
    unit ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_push :
    ctx:Terrat_storage.t Ctx.t ->
    account:S.Api.Account.t ->
    user:S.Api.User.t ->
    repo:S.Api.Repo.t ->
    branch:S.Api.Ref.t ->
    unit ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_work_manifest_initiate :
    ctx:Terrat_storage.t Ctx.t ->
    encryption_key:Cstruct.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_initiate.t ->
    (Terrat_api_components.Work_manifest.t option, [> `Error ]) result Abb.Future.t

  val run_work_manifest_result :
    ctx:Terrat_storage.t Ctx.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_result.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_plan_store :
    ctx:Terrat_storage.t Ctx.t ->
    Uuidm.t ->
    Terrat_api_components.Plan_create.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val run_plan_fetch :
    ctx:Terrat_storage.t Ctx.t ->
    Uuidm.t ->
    Terrat_dirspace.t ->
    (string option, [> `Error ]) result Abb.Future.t

  (** Signal that the work manifest failed for out-of-band reasons. *)
  val run_work_manifest_failure :
    ctx:Terrat_storage.t Ctx.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

  val run_scheduled_drift : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
  val run_plan_cleanup : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
  val run_flow_state_cleanup : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
  val run_repo_config_cleanup : Terrat_storage.t Ctx.t -> (unit, [> `Error ]) result Abb.Future.t
end

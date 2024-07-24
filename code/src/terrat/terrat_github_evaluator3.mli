module S : sig
  module User : sig
    type t

    val make : string -> t
  end

  module Account : sig
    type t

    val make : installation_id:int -> unit -> t
  end

  module Ref : sig
    type t = string
  end

  module Repo : sig
    type t

    val make : id:int -> name:string -> owner:string -> unit -> t
    val id : t -> int
    val name : t -> string
    val owner : t -> string
  end

  module Remote_repo : sig
    module R = Githubc2_components.Full_repository
    module U = Githubc2_components.Simple_user

    type t = R.t
  end

  module Pull_request : sig
    module Diff : sig
      type t = Terrat_change.Diff.t
    end

    module State : sig
      module Merged : sig
        type t = Terrat_pull_request.State.Merged.t
      end

      module Open_status : sig
        type t = Terrat_pull_request.State.Open_status.t
      end

      type t = Terrat_pull_request.State.t
    end

    type fetched = {
      checks : bool;
      diff : Diff.t list;
      is_draft_pr : bool;
      mergeable : bool option;
      provisional_merge_ref : Ref.t option;
    }

    type stored = unit

    type 'a t = {
      base_branch_name : Ref.t;
      base_ref : Ref.t;
      branch_name : Ref.t;
      branch_ref : Ref.t;
      id : int;
      repo : Repo.t;
      state : State.t;
      title : string option;
      user : string option;
      value : 'a;
    }
  end
end

type run_err = [ `Error ] [@@deriving show]

module State : sig
  type t
end

module Yield : sig
  type t
end

val run_pull_request_open :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  account:S.Account.t ->
  user:S.User.t ->
  repo:S.Repo.t ->
  pull_request_id:int ->
  unit ->
  (unit, [> run_err ]) result Abb.Future.t

val run_pull_request_close :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  account:S.Account.t ->
  user:S.User.t ->
  repo:S.Repo.t ->
  pull_request_id:int ->
  unit ->
  (unit, [> run_err ]) result Abb.Future.t

val run_pull_request_sync :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  account:S.Account.t ->
  user:S.User.t ->
  repo:S.Repo.t ->
  pull_request_id:int ->
  unit ->
  (unit, [> run_err ]) result Abb.Future.t

val run_pull_request_ready_for_review :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  account:S.Account.t ->
  user:S.User.t ->
  repo:S.Repo.t ->
  pull_request_id:int ->
  unit ->
  (unit, [> run_err ]) result Abb.Future.t

val run_pull_request_comment :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  account:S.Account.t ->
  user:S.User.t ->
  comment:Terrat_comment.t ->
  repo:S.Repo.t ->
  pull_request_id:int ->
  comment_id:int ->
  unit ->
  (unit, [> run_err ]) result Abb.Future.t

val run_push :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  account:S.Account.t ->
  user:S.User.t ->
  repo:S.Repo.t ->
  branch:S.Ref.t ->
  unit ->
  (unit, [> run_err ]) result Abb.Future.t

val work_manifest_initiate :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  encryption_key:Cstruct.t ->
  Uuidm.t ->
  Terrat_api_components.Work_manifest_initiate.t ->
  (Terrat_api_components.Work_manifest.t option, [> `Error ]) result Abb.Future.t

val work_manifest_result :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  Uuidm.t ->
  Terrat_api_components.Work_manifest_result.t ->
  (unit, [> `Error ]) result Abb.Future.t

val work_manifest_failure :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

val plan_store :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  Uuidm.t ->
  Terrat_api_components.Plan_create.t ->
  (unit, [> `Error ]) result Abb.Future.t

val plan_fetch :
  ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
  Uuidm.t ->
  Terrat_dirspace.t ->
  (string option, [> `Error ]) result Abb.Future.t

module Service : sig
  val drift : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  val flow_state_cleanup : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  val plan_cleanup : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
end

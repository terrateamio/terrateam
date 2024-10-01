module S : sig
  module Client : sig
    type t
  end

  module User : sig
    type t

    val make : string -> t
  end

  module Account : sig
    type t

    val make : installation_id:int -> unit -> t
    val id : t -> int
  end

  module Ref : sig
    type t = string

    val to_string : t -> string
  end

  module Repo : sig
    type t

    val make : id:int -> name:string -> owner:string -> unit -> t
    val id : t -> int
    val name : t -> string
    val owner : t -> string
    val to_string : t -> string
  end

  module Remote_repo : sig
    module R = Githubc2_components.Full_repository
    module U = Githubc2_components.Simple_user

    type t = R.t

    val to_repo : t -> Repo.t
    val default_branch : t -> Ref.t
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

  val fetch_branch_sha :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    (Ref.t option, [> `Error ]) result Abb.Future.t

  val fetch_file :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    string ->
    (string option, [> `Error ]) result Abb.Future.t

  val fetch_remote_repo :
    request_id:string -> Client.t -> Repo.t -> (Remote_repo.t, [> `Error ]) result Abb.Future.t

  val fetch_centralized_repo :
    request_id:string ->
    Client.t ->
    string ->
    (Remote_repo.t option, [> `Error ]) result Abb.Future.t

  val repo_config_of_json :
    Yojson.Safe.t ->
    ( Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
      [> Terrat_base_repo_config_v1.of_version_1_err | `Repo_config_parse_err of string ] )
    result
    Abb.Future.t
end

module Make
    (Terratc : Terratc_intf.S
                 with type Github.Client.t = S.Client.t
                  and type Github.Account.t = S.Account.t
                  and type Github.Repo.t = S.Repo.t
                  and type Github.Ref.t = S.Ref.t) : sig
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
    ctx:Terrat_storage.t Terrat_evaluator3.Ctx.t ->
    Uuidm.t ->
    (unit, [> `Error ]) result Abb.Future.t

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
    val repo_config_cleanup : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  end
end

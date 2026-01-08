module type ID = sig
  type t [@@deriving yojson, eq, show]

  val of_string : string -> t option
  val to_string : t -> string
end

module type CONFIG = sig
  type t
  type vcs_config

  val make : config:Terrat_config.t -> vcs_config:vcs_config -> unit -> t
  val config : t -> Terrat_config.t
  val vcs_config : t -> vcs_config
end

module type S = sig
  module Config : CONFIG

  module User : sig
    module Id : ID

    type t [@@deriving yojson]

    val make : Id.t -> t
    val id : t -> Id.t
    val to_string : t -> string
  end

  module Account : sig
    module Id : ID

    type t [@@deriving show, eq, yojson]

    val make : Id.t -> t
    val id : t -> Id.t
    val to_string : t -> string
  end

  module Client : sig
    type t
    type native

    val to_native : t -> native
  end

  module Comment : sig
    module Id : sig
      include ID

      val compare : t -> t -> int
    end

    type t [@@deriving eq, yojson]

    val make : id:Id.t -> unit -> t
    val id : t -> Id.t
  end

  module Ref : sig
    type t [@@deriving show, eq, yojson]

    val to_string : t -> string
    val of_string : string -> t
  end

  module Repo : sig
    module Id : ID

    type t [@@deriving show, eq, yojson]

    val make : id:Id.t -> name:string -> owner:string -> unit -> t
    val id : t -> Id.t
    val owner : t -> string
    val name : t -> string
    val to_string : t -> string
  end

  module Remote_repo : sig
    type t [@@deriving yojson]

    val to_repo : t -> Repo.t
    val default_branch : t -> Ref.t
  end

  module Pull_request : sig
    module Id : ID

    include
      module type of Terrat_pull_request
        with type ('id, 'diff, 'checks, 'repo, 'ref) t =
          ('id, 'diff, 'checks, 'repo, 'ref) Terrat_pull_request.t
         and type State.Merged.t = Terrat_pull_request.State.Merged.t
         and type State.Open_status.t = Terrat_pull_request.State.Open_status.t
         and type State.t = Terrat_pull_request.State.t

    type ('diff, 'checks) t = (Id.t, 'diff, 'checks, Repo.t, Ref.t) Terrat_pull_request.t
    [@@deriving show, to_yojson]
  end

  val create_client :
    request_id:string ->
    Config.t ->
    Account.t ->
    Pgsql_io.t ->
    (Client.t, [> `Error ]) result Abb.Future.t

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

  val fetch_tree :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    (string list, [> `Error ]) result Abb.Future.t

  val comment_on_pull_request :
    request_id:string ->
    Client.t ->
    ('diff, 'checks) Pull_request.t ->
    string ->
    (Comment.Id.t, [> `Error ]) result Abb.Future.t

  val delete_pull_request_comment :
    request_id:string ->
    Client.t ->
    ('diff, 'checks) Pull_request.t ->
    Comment.Id.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val minimize_pull_request_comment :
    request_id:string ->
    Client.t ->
    ('diff, 'checks) Pull_request.t ->
    Comment.Id.t ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_pull_request :
    request_id:string ->
    Account.t ->
    Client.t ->
    Repo.t ->
    Pull_request.Id.t ->
    ((Terrat_change.Diff.t list, bool) Pull_request.t, [> `Error ]) result Abb.Future.t

  val fetch_pull_request_reviews :
    request_id:string ->
    Repo.t ->
    Pull_request.Id.t ->
    Client.t ->
    (Terrat_pull_request_review.t list, [> `Error ]) result Abb.Future.t

  val fetch_pull_request_requested_reviews :
    request_id:string ->
    Repo.t ->
    Pull_request.Id.t ->
    Client.t ->
    (Terrat_base_repo_config_v1.Access_control.Match.t list, [> `Error ]) result Abb.Future.t

  val fetch_diff_files :
    request_id:string ->
    base_ref:Ref.t ->
    branch_ref:Ref.t ->
    Repo.t ->
    Client.t ->
    (Terrat_change.Diff.t list, [> `Error ]) result Abb.Future.t

  val react_to_comment :
    request_id:string ->
    Client.t ->
    ('a, 'b) Pull_request.t ->
    int ->
    (unit, [> `Error ]) result Abb.Future.t

  val create_commit_checks :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    Terrat_commit_check.t list ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_commit_checks :
    request_id:string ->
    Client.t ->
    Repo.t ->
    Ref.t ->
    (Terrat_commit_check.t list, [> `Error ]) result Abb.Future.t

  val merge_pull_request :
    request_id:string ->
    Client.t ->
    ('diff, 'checks) Pull_request.t ->
    Terrat_base_repo_config_v1.Automerge.Merge_strategy.t ->
    (unit, [> `Error | `Merge_err of string ]) result Abb.Future.t

  val delete_branch :
    request_id:string -> Client.t -> Repo.t -> string -> (unit, [> `Error ]) result Abb.Future.t

  val is_member_of_team :
    request_id:string ->
    team:string ->
    user:User.t ->
    Repo.t ->
    Client.t ->
    (bool, [> `Error ]) result Abb.Future.t

  val get_repo_role :
    request_id:string ->
    Repo.t ->
    User.t ->
    Client.t ->
    (string option, [> `Error ]) result Abb.Future.t

  val find_workflow_file :
    request_id:string -> Repo.t -> Client.t -> (string option, [> `Error ]) result Abb.Future.t
end

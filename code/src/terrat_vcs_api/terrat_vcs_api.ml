module type S = sig
  module User : sig
    type t [@@deriving yojson]

    val to_string : t -> string
  end

  module Account : sig
    type t [@@deriving eq, yojson]

    val to_string : t -> string
  end

  module Client : sig
    type t
  end

  module Drift : sig
    type t
  end

  module Ref : sig
    type t [@@deriving eq, yojson]

    val to_string : t -> string
    val of_string : string -> t
  end

  module Repo : sig
    type t [@@deriving eq, yojson]

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
    type t

    val base_branch_name : t -> Ref.t
    val base_ref : t -> Ref.t
    val branch_name : t -> Ref.t
    val branch_ref : t -> Ref.t
    val diff : t -> Terrat_change.Diff.t list
    val id : t -> string
    val is_draft_pr : t -> bool
    val provisional_merge_ref : t -> Ref.t option
    val repo : t -> Repo.t
    val state : t -> Terrat_pull_request.State.t
  end

  val create_client :
    request_id:string -> Terrat_config.t -> Account.t -> (Client.t, [> `Error ]) result Abb.Future.t

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
    Pull_request.t ->
    string ->
    (unit, [> `Error ]) result Abb.Future.t

  val fetch_pull_request :
    request_id:string ->
    Account.t ->
    Client.t ->
    Repo.t ->
    int ->
    (Pull_request.t, [> `Error ]) result Abb.Future.t

  val react_to_comment :
    request_id:string -> Client.t -> Repo.t -> int -> (unit, [> `Error ]) result Abb.Future.t

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
    Pull_request.t ->
    (unit, [> `Error | `Merge_err of string ]) result Abb.Future.t

  val delete_branch :
    request_id:string -> Client.t -> string -> (unit, [> `Error ]) result Abb.Future.t
end

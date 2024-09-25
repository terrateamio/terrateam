module type S = sig
  module Github : sig
    module Client : sig
      type t
    end

    module Repo : sig
      type t

      val to_string : t -> string
      val owner : t -> string
      val name : t -> string
    end

    module Ref : sig
      type t

      val to_string : t -> string
    end

    module Remote_repo : sig
      type t

      val to_repo : t -> Repo.t
      val default_branch : t -> Ref.t
    end

    val fetch_branch_sha :
      request_id:string ->
      Client.t ->
      Repo.t ->
      Ref.t ->
      (Ref.t option, [> `Error ]) result Abb.Future.t

    val fetch_remote_repo :
      request_id:string -> Client.t -> Repo.t -> (Remote_repo.t, [> `Error ]) result Abb.Future.t

    val fetch_file :
      request_id:string ->
      Client.t ->
      Repo.t ->
      Ref.t ->
      string ->
      (string option, [> `Error ]) result Abb.Future.t

    val repo_config_of_json :
      Yojson.Safe.t ->
      ( Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
        [> Terrat_base_repo_config_v1.of_version_1_err | `Repo_config_parse_err of string ] )
      result
      Abb.Future.t
  end
end

module Make (M : S) :
  Terratc_intf.S
    with type Github.Client.t = M.Github.Client.t
     and type Github.Repo.t = M.Github.Repo.t
     and type Github.Remote_repo.t = M.Github.Remote_repo.t
     and type Github.Ref.t = M.Github.Ref.t

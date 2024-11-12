module Repo_config = struct
  type fetch_err =
    [ Terrat_base_repo_config_v1.of_version_1_err
    | `Repo_config_parse_err of string * string
    | Jsonu.merge_err
    | `Json_decode_err of string * string
    | `Unexpected_err of string
    | `Yaml_decode_err of string * string
    | `Error
    ]
  [@@deriving show]
end

module Access_control = struct
  type query_err = [ `Error ] [@@deriving show]
  type err = query_err [@@deriving show]
end

module type S = sig
  module Github : sig
    module Client : sig
      type t
    end

    module Account : sig
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

    module Access_control : sig
      module Ctx : sig
        type t

        val make :
          client:Githubc2_abb.t -> config:Terrat_config.t -> repo:Repo.t -> user:string -> unit -> t
      end

      val query :
        Ctx.t ->
        Terrat_base_repo_config_v1.Access_control.Match.t ->
        (bool, [> Access_control.query_err ]) result Abb.Future.t

      val is_ci_changed :
        Ctx.t -> Terrat_change.Diff.t list -> (bool, [> Access_control.err ]) result Abb.Future.t

      val set_user : string -> Ctx.t -> Ctx.t
    end

    module Repo_config : sig
      val fetch_with_provenance :
        ?system_defaults:Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t ->
        ?built_config:Yojson.Safe.t ->
        string ->
        Client.t ->
        Repo.t ->
        Ref.t ->
        ( string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
          [> Repo_config.fetch_err ] )
        result
        Abb.Future.t
    end

    module Commit_check : sig
      val make_commit_check :
        ?work_manifest:('a, 'b) Terrat_work_manifest3.Existing.t ->
        config:Terrat_config.t ->
        description:string ->
        title:string ->
        status:Terrat_commit_check.Status.t ->
        repo:Repo.t ->
        Account.t ->
        Terrat_commit_check.t
    end

    module Ui : sig
      val work_manifest_url :
        Terrat_config.t -> Account.t -> ('a, 'b) Terrat_work_manifest3.Existing.t -> Uri.t option
    end
  end
end

type fetch_repo_config_with_provenance_err =
  [ Terrat_base_repo_config_v1.of_version_1_err
  | `Repo_config_parse_err of string * string
  | Jsonu.merge_err
  | `Json_decode_err of string * string
  | `Unexpected_err of string
  | `Yaml_decode_err of string * string
  | `Error
  ]
[@@deriving show]

type access_control_query_err = [ `Error ] [@@deriving show]
type access_control_err = access_control_query_err [@@deriving show]

module type S = sig
  module Api : Terrat_vcs_api.S

  module Repo_config : sig
    val fetch_with_provenance :
      ?system_defaults:Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t ->
      ?built_config:Yojson.Safe.t ->
      string ->
      Api.Client.t ->
      Api.Repo.t ->
      Api.Ref.t ->
      ( string list * Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
        [> fetch_repo_config_with_provenance_err ] )
      result
      Abb.Future.t
  end

  module Access_control : sig
    module Ctx : sig
      type t

      val make :
        client:Api.Client.t -> config:Terrat_config.t -> repo:Api.Repo.t -> user:string -> unit -> t
    end

    val query :
      Ctx.t ->
      Terrat_base_repo_config_v1.Access_control.Match.t ->
      (bool, [> access_control_query_err ]) result Abb.Future.t

    val is_ci_changed :
      Ctx.t -> Terrat_change.Diff.t list -> (bool, [> access_control_err ]) result Abb.Future.t

    val set_user : string -> Ctx.t -> Ctx.t
  end

  module Commit_check : sig
    val make_commit_check :
      ?work_manifest:('a, 'b) Terrat_work_manifest3.Existing.t ->
      config:Terrat_config.t ->
      description:string ->
      title:string ->
      status:Terrat_commit_check.Status.t ->
      repo:Api.Repo.t ->
      Api.Account.t ->
      Terrat_commit_check.t
  end

  module Ui : sig
    val work_manifest_url :
      Terrat_config.t -> Api.Account.t -> ('a, 'b) Terrat_work_manifest3.Existing.t -> Uri.t option
  end
end

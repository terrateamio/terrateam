type get_access_token_err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | `Refresh_token_err of Githubc2_abb.call_err
  | `Renew_refresh_token
  ]
[@@deriving show]

type get_installation_access_token_err =
  [ Githubc2_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type verify_user_installation_access_err =
  [ get_access_token_err
  | Githubc2_abb.call_err
  | `Forbidden
  ]
[@@deriving show]

type get_user_installations_err =
  [ get_access_token_err
  | Githubc2_abb.call_err
  ]
[@@deriving show]

type fetch_repo_config_err =
  [ Githubc2_abb.call_err
  | Abb_process.check_output_err
  | `Repo_config_in_sub_module
  | `Repo_config_is_symlink
  | `Repo_config_is_dir
  | `Repo_config_permission_denied
  | `Repo_config_parse_err of string
  | `Repo_config_unknown_err
  ]
[@@deriving show]

type publish_comment_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Gone of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type publish_reaction_err =
  [ Githubc2_abb.call_err
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_tree_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_team_membership_in_org_err = Githubc2_abb.call_err [@@deriving show]
type get_repo_collaborator_permission_err = Githubc2_abb.call_err [@@deriving show]

type compare_commits_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Internal_server_error of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

module Commit_status : sig
  type create_err = Githubc2_abb.call_err [@@deriving show]

  type list_err =
    [ Githubc2_abb.call_err
    | `Error
    | `Moved_permanently of Githubc2_components.Basic_error.t
    ]
  [@@deriving show]

  module Create : sig
    module T : sig
      type t [@@deriving show]

      val make :
        ?target_url:string -> ?description:string -> ?context:string -> state:string -> unit -> t
    end

    type t = T.t list
  end

  val create :
    access_token:string ->
    owner:string ->
    repo:string ->
    sha:string ->
    Create.t ->
    (unit, [> create_err ]) result Abb.Future.t

  val list :
    access_token:string ->
    owner:string ->
    repo:string ->
    sha:string ->
    unit ->
    (Githubc2_components.Status.t list, [> list_err ]) result Abb.Future.t
end

module Status_check : sig
  type list_err = Githubc2_abb.call_err [@@deriving show]

  val list :
    access_token:string ->
    owner:string ->
    repo:string ->
    ref_:string ->
    unit ->
    (Githubc2_components.Check_run.t list, [> list_err ]) result Abb.Future.t
end

module Pull_request_reviews : sig
  type list_err =
    [ `Error
    | Githubc2_abb.call_err
    ]
  [@@deriving show]

  val list :
    access_token:string ->
    owner:string ->
    repo:string ->
    pull_number:int ->
    unit ->
    (Githubc2_components.Pull_request_review.t list, [> list_err ]) result Abb.Future.t
end

val create : Githubc2_abb.Authorization.t -> Githubc2_abb.t

(** Perform a call but with a retry *)
val call :
  ?tries:int ->
  Githubc2_abb.t ->
  'a Openapi.Request.t ->
  ('a Openapi.Response.t, [> Githubc2_abb.call_err ]) result Abb_scheduler_kqueue.Future.t

val get_installation_access_token :
  Terrat_config.t -> int -> (string, [> get_installation_access_token_err ]) result Abb.Future.t

(** Load the configuration from the repo, which should be a YAML file if it
   exists.  If it exists, convert it to JSON and load it.  If it does not exist
   then create a default one.  The [python] variable is a bit strange here but
   that is because Ocaml does not have great Yaml support so we piggyback on
   Python for converting to JSON. *)
val fetch_repo_config :
  python:string ->
  access_token:string ->
  owner:string ->
  repo:string ->
  string ->
  (Terrat_repo_config.Version_1.t, [> fetch_repo_config_err ]) result Abb.Future.t

val fetch_pull_request_files :
  access_token:string ->
  owner:string ->
  pull_number:int ->
  string ->
  (Githubc2_components.Diff_entry.t list, [> Githubc2_abb.call_err | `Error ]) result Abb.Future.t

val fetch_changed_files :
  access_token:string ->
  owner:string ->
  repo:string ->
  base:string ->
  string ->
  (Githubc2_repos.Compare_commits.Responses.t Openapi.Response.t, [> Githubc2_abb.call_err ]) result
  Abb.Future.t

val fetch_pull_request :
  access_token:string ->
  owner:string ->
  repo:string ->
  int ->
  (Githubc2_pulls.Get.Responses.t Openapi.Response.t, [> Githubc2_abb.call_err ]) result
  Abb.Future.t

val compare_commits :
  access_token:string ->
  owner:string ->
  repo:string ->
  string * string ->
  (Githubc2_components.Commit_comparison.Primary.Files.t, [> compare_commits_err ]) result
  Abb.Future.t

(* val get_access_token :
 *   Terrat_storage.t ->
 *   string ->
 *   string ->
 *   string ->
 *   (string, [> get_access_token_err ]) result Abb.Future.t *)

(* val get_user_installations :
 *   Terrat_config.t ->
 *   Terrat_storage.t ->
 *   Githubc_v3.Schema.t ->
 *   string ->
 *   (Terrat_data.Response.Installation.t list, [> get_user_installations_err ]) result Abb.Future.t
 * 
 * val verify_user_installation_access :
 *   Terrat_config.t ->
 *   Terrat_storage.t ->
 *   Githubc_v3.Schema.t ->
 *   int64 ->
 *   string ->
 *   (unit, [> verify_user_installation_access_err ]) result Abb.Future.t
 * 
 * val verify_admin_installation_access :
 *   Terrat_config.t ->
 *   Terrat_storage.t ->
 *   Githubc_v3.Schema.t ->
 *   int64 ->
 *   string ->
 *   (unit, [> verify_user_installation_access_err ]) result Abb.Future.t *)

val load_workflow :
  access_token:string ->
  owner:string ->
  repo:string ->
  (int option, [> get_installation_access_token_err ]) result Abb.Future.t

val publish_comment :
  access_token:string ->
  owner:string ->
  repo:string ->
  pull_number:int ->
  string ->
  (unit, [> publish_comment_err ]) result Abb.Future.t

val react_to_comment :
  ?content:string ->
  access_token:string ->
  owner:string ->
  repo:string ->
  comment_id:int ->
  unit ->
  (unit, [> publish_reaction_err ]) result Abb.Future.t

val get_tree :
  access_token:string ->
  owner:string ->
  repo:string ->
  sha:string ->
  unit ->
  (string list, [> get_tree_err ]) result Abb.Future.t

val get_team_membership_in_org :
  access_token:string ->
  org:string ->
  team:string ->
  user:string ->
  unit ->
  (bool, [> get_team_membership_in_org_err ]) result Abb.Future.t

val get_repo_collaborator_permission :
  access_token:string ->
  org:string ->
  repo:string ->
  user:string ->
  unit ->
  (string option, [> get_repo_collaborator_permission_err ]) result Abb.Future.t

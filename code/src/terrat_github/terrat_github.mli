type user_err =
  [ Githubc2_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_modified
  | `Unauthorized of Githubc2_components.Basic_error.t
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

type get_user_installations_err =
  [ Githubc2_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_modified
  ]
[@@deriving show]

type get_installation_repos_err =
  [ Githubc2_abb.call_err
  | `Not_modified
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unauthorized of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

type fetch_file_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Found
  | `Not_file
  ]
[@@deriving show]

type fetch_repo_err =
  [ Githubc2_abb.call_err
  | `Moved_permanently of Githubc2_repos.Get.Responses.Moved_permanently.t
  | `Forbidden of Githubc2_repos.Get.Responses.Forbidden.t
  | `Not_found of Githubc2_repos.Get.Responses.Not_found.t
  ]
[@@deriving show]

type create_pull_request_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type create_ref_err =
  [ Githubc2_abb.call_err
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type fetch_branch_err =
  [ Githubc2_abb.call_err
  | `Moved_permanently of Githubc2_repos.Get_branch.Responses.Moved_permanently.t
  | `Not_found of Githubc2_repos.Get_branch.Responses.Not_found.t
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

type get_tree_raw_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_tree_err =
  [ Githubc2_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type create_tree_err =
  [ Githubc2_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type create_commit_err =
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
    owner:string ->
    repo:string ->
    sha:string ->
    creates:Create.t ->
    Githubc2_abb.t ->
    (unit, [> create_err ]) result Abb.Future.t

  val list :
    owner:string ->
    repo:string ->
    sha:string ->
    Githubc2_abb.t ->
    (Githubc2_components.Status.t list, [> list_err ]) result Abb.Future.t
end

module Status_check : sig
  type list_err = Githubc2_abb.call_err [@@deriving show]

  val list :
    owner:string ->
    repo:string ->
    ref_:string ->
    Githubc2_abb.t ->
    (Githubc2_components.Check_run.t list, [> list_err ]) result Abb.Future.t
end

module Pull_request_reviews : sig
  type list_err =
    [ `Error
    | Githubc2_abb.call_err
    ]
  [@@deriving show]

  val list :
    owner:string ->
    repo:string ->
    pull_number:int ->
    Githubc2_abb.t ->
    (Githubc2_components.Pull_request_review.t list, [> list_err ]) result Abb.Future.t
end

val create : Terrat_config.t -> Githubc2_abb.Authorization.t -> Githubc2_abb.t

val with_client :
  Terrat_config.t ->
  Githubc2_abb.Authorization.t ->
  (Githubc2_abb.t -> 'a Abb.Future.t) ->
  'a Abb.Future.t

(** Perform a call but with a retry *)
val call :
  ?tries:int ->
  Githubc2_abb.t ->
  'a Openapi.Request.t ->
  ('a Openapi.Response.t, [> Githubc2_abb.call_err ]) result Abb_scheduler_kqueue.Future.t

val user :
  config:Terrat_config.t ->
  access_token:string ->
  unit ->
  (Githubc2_users.Get_authenticated.Responses.OK.t, [> user_err ]) result Abb.Future.t

val get_installation_access_token :
  ?expiration_sec:float ->
  ?permissions:Githubc2_components.App_permissions.t ->
  Terrat_config.t ->
  int ->
  (string, [> get_installation_access_token_err ]) result Abb.Future.t

val fetch_repo :
  owner:string ->
  repo:string ->
  Githubc2_abb.t ->
  (Githubc2_components.Full_repository.t, [> fetch_repo_err ]) result Abb.Future.t

val fetch_branch :
  owner:string ->
  repo:string ->
  branch:string ->
  Githubc2_abb.t ->
  (Githubc2_components.Branch_with_protection.t, [> fetch_branch_err ]) result Abb.Future.t

val fetch_file :
  owner:string ->
  repo:string ->
  ref_:string ->
  path:string ->
  Githubc2_abb.t ->
  (Githubc2_components.Content_file.t option, [> fetch_file_err ]) result Abb.Future.t

val fetch_pull_request_files :
  owner:string ->
  repo:string ->
  pull_number:int ->
  Githubc2_abb.t ->
  (Githubc2_components.Diff_entry.t list, [> Githubc2_abb.call_err | `Error ]) result Abb.Future.t

val fetch_changed_files :
  owner:string ->
  repo:string ->
  base:string ->
  head:string ->
  Githubc2_abb.t ->
  (Githubc2_repos.Compare_commits.Responses.t Openapi.Response.t, [> Githubc2_abb.call_err ]) result
  Abb.Future.t

val fetch_pull_request :
  owner:string ->
  repo:string ->
  pull_number:int ->
  Githubc2_abb.t ->
  (Githubc2_pulls.Get.Responses.t Openapi.Response.t, [> Githubc2_abb.call_err ]) result
  Abb.Future.t

val create_pull_request :
  owner:string ->
  repo:string ->
  base_branch:string ->
  branch:string ->
  title:string ->
  body:string ->
  Githubc2_abb.t ->
  (Githubc2_components.Pull_request.t, [> create_pull_request_err ]) result Abb.Future.t

val create_ref :
  owner:string ->
  repo:string ->
  ref_:string ->
  sha:string ->
  Githubc2_abb.t ->
  (unit, [> create_ref_err ]) result Abb.Future.t

val compare_commits :
  owner:string ->
  repo:string ->
  string * string ->
  Githubc2_abb.t ->
  (Githubc2_components.Commit_comparison.Primary.Files.t, [> compare_commits_err ]) result
  Abb.Future.t

val get_user_installations :
  Githubc2_abb.t ->
  (Githubc2_components.Installation.t list, [> get_user_installations_err ]) result Abb.Future.t

val get_installation_repos :
  Githubc2_abb.t ->
  (Githubc2_components.Repository.t list, [> get_installation_repos_err ]) result Abb.Future.t

val find_workflow_file :
  owner:string ->
  repo:string ->
  Githubc2_abb.t ->
  (string option, [> get_installation_access_token_err ]) result Abb.Future.t

val load_workflow :
  owner:string ->
  repo:string ->
  Githubc2_abb.t ->
  (int option, [> get_installation_access_token_err ]) result Abb.Future.t

val publish_comment :
  owner:string ->
  repo:string ->
  pull_number:int ->
  body:string ->
  Githubc2_abb.t ->
  (unit, [> publish_comment_err ]) result Abb.Future.t

val react_to_comment :
  ?content:string ->
  owner:string ->
  repo:string ->
  comment_id:int ->
  Githubc2_abb.t ->
  (unit, [> publish_reaction_err ]) result Abb.Future.t

val get_tree_raw :
  ?recursive:bool ->
  owner:string ->
  repo:string ->
  sha:string ->
  Githubc2_abb.t ->
  (Githubc2_components.Git_tree.t, [> get_tree_raw_err ]) result Abb.Future.t

val get_tree :
  owner:string ->
  repo:string ->
  sha:string ->
  Githubc2_abb.t ->
  (string list, [> get_tree_err ]) result Abb.Future.t

val create_tree :
  owner:string ->
  repo:string ->
  base_tree:string ->
  tree:Githubc2_git.Create_tree.Request_body.Primary.Tree.Items.Primary.t list ->
  Githubc2_abb.t ->
  (string, [> create_tree_err ]) result Abb.Future.t

val create_commit :
  owner:string ->
  repo:string ->
  msg:string ->
  parent:string ->
  tree_sha:string ->
  Githubc2_abb.t ->
  (string, [> create_commit_err ]) result Abb.Future.t

val get_team_membership_in_org :
  org:string ->
  team:string ->
  user:string ->
  Githubc2_abb.t ->
  (bool, [> get_team_membership_in_org_err ]) result Abb.Future.t

val get_repo_collaborator_permission :
  org:string ->
  repo:string ->
  user:string ->
  Githubc2_abb.t ->
  (string option, [> get_repo_collaborator_permission_err ]) result Abb.Future.t

(** GitHub does not include Oauth operations in their JSON schema, so
    implementing here. *)
module Oauth : sig
  type authorize_err =
    [ `Authorize_err of string
    | Cohttp_abb.request_err
    ]
  [@@deriving show]

  type refresh_err =
    [ `Refresh_err of string
    | `Bad_refresh_token
    | Cohttp_abb.request_err
    ]
  [@@deriving show]

  module Response : sig
    type t = {
      access_token : string;
      scope : string;
      token_type : string;
      refresh_token : string option; [@default None]
      refresh_token_expires_in : int option; [@default None]
      expires_in : int option; [@default None]
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  val authorize :
    config:Terrat_config.t -> string -> (Response.t, [> authorize_err ]) result Abb.Future.t

  val refresh :
    config:Terrat_config.t -> string -> (Response.t, [> refresh_err ]) result Abb.Future.t
end

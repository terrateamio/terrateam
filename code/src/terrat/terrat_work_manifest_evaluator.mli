module Dirspace_map : module type of CCMap.Make (Terrat_change.Dirspace)

type 'pull_request err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | `Not_found
  | `Work_manifest_already_run
  | `Work_manifest_in_queue_state
  | `Dirspaces_without_valid_plans of Terrat_change.Dirspace.t list
  | `Dirspaces_owned_by_other_pull_requests of (Terrat_change.Dirspace.t * 'pull_request) list
  | `Error
  ]
[@@deriving show]

module Work_manifest : sig
  type 'a t = 'a Terrat_work_manifest.Existing.t
end

module type S = sig
  type t

  module Pull_request : sig
    type t

    module Lite : sig
      type t [@@deriving show]
    end
  end

  val request_id : t -> string

  val initiate_work_manifest :
    Pgsql_io.t -> t -> (Pull_request.t Work_manifest.t option, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    Pgsql_io.t ->
    t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    Pgsql_io.t ->
    t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Pull_request.Lite.t Dirspace_map.t, [> `Error ]) result Abb.Future.t
end

module Make (S : S) : sig
  type nonrec err = S.Pull_request.Lite.t err [@@deriving show]

  val run :
    Terrat_storage.t ->
    S.t ->
    (S.Pull_request.t Work_manifest.t option, [> err ]) result Abb.Future.t
end

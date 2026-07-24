(** GitHub implementation of the unified pull request summary comment.

    The flow has two halves. While a work manifest result is being processed (inside its
    transaction), {!mark_dirty} bumps the dirty counter of the pull request's tracking row so the
    refresh is committed atomically with the results. After the transaction commits, {!drain} runs
    on a fresh connection: it takes an advisory lock so only one publisher runs per pull request,
    recomputes the state of every dirspace, renders it, updates the tracked comment in place
    (posting a new one if it disappeared), and clears the dirty counter it observed. If new results
    arrived while publishing, the counter no longer matches and it retries. *)

val mark_dirty :
  request_id:string -> Pgsql_io.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

(** Like {!mark_dirty} but never creates the tracking row, so pull requests that do not publish a
    unified comment are unaffected. Used by failure paths, which cannot cheaply consult the repo
    config. *)
val mark_dirty_if_tracked :
  request_id:string -> Pgsql_io.t -> Uuidm.t -> (unit, [> `Error ]) result Abb.Future.t

val drain :
  request_id:string ->
  Terrat_vcs_api_github.Config.t ->
  Pgsql_pool.t ->
  Uuidm.t ->
  unit Abb.Future.t

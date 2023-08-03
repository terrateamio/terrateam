val start : Terrat_storage.t -> unit Abb.Future.t

(** Delete all plans matching the dir and workspace for the pull request
   matching the work manfiest *)
val clean :
  work_manifest:Uuidm.t ->
  dir:string ->
  workspace:string ->
  Pgsql_io.t ->
  (unit, [> Pgsql_io.err ]) result Abb.Future.t

(** Clean up all plans for the matching pull request. *)
val clean_pull_request :
  repo_id:int -> pull_number:int -> Pgsql_io.t -> (unit, [> Pgsql_io.err ]) result Abb.Future.t

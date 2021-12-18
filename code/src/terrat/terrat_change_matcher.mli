type t = {
  dirspaceflow : Terrat_change.Dirspaceflow.t;
  when_modified : Terrat_repo_config.When_modified.t;
}
[@@deriving show]

val match_diff :
  ?tag_query:Terrat_tag_set.t ->
  Terrat_repo_config.Version_1.t ->
  Terrat_change.Diff.t list ->
  t list

(** Given a list of dirspaces, map them to their directory in the repo config.
   If a dir path in the dirspace is not present in the repo config, it gets the
   default [When_modified] configuration.  If a directory is present but the
   workspace is not, it gets the default set of tags. *)
val map_dirspace :
  ?tag_query:Terrat_tag_set.t ->
  Terrat_repo_config.Version_1.t ->
  Terrat_change.Dirspace.t list ->
  t list

(** Merge a list with de-duplication.  Any duplicates are taken from the right
   list.  The order of the output list is unspecified. *)
val merge_dedup : t list -> t list -> t list

val dirspaceflow : t -> Terrat_change.Dirspaceflow.t

(** A change match.  The [when_modified] section contains the entire
   configuration for the dirspace. *)
type t = {
  create_and_select_workspace : bool;
  dirspace : Terrat_change.Dirspace.t;
  tags : Terrat_tag_set.t;
  when_modified : Terrat_repo_config.When_modified.t;
}
[@@deriving show]

module Dirs : sig
  type t [@@deriving show]
end

(** Thrown when an input [diff] or [dirspace] has no matching entry in the
   [Dirs] config.  *)
exception No_matching_dir of string

(** Given a list of files in the repository and a version of the config,
   construct the [dirs] configuration that matches all of the files. *)
val synthesize_dir_config :
  file_list:string list ->
  Terrat_repo_config.Version_1.t ->
  (Dirs.t, [> `Bad_glob of string ]) result

(** Given a dirs configuration and a diff, return the match.  If there is no
   matching entry in the dirs section, raise [No_matching_dir] exception.  A
   diff can result in multiple matches being generated, for example renaming a
   file might impact two directories.  It takes care of de-duping the results.
   That is, if there are multiple changes that map to the same dirspace, the
   dirspace will appear only once in the output. *)
val match_diff_list : Dirs.t -> Terrat_change.Diff.t list -> t list

(** Given a dirs configuration and dirspace, turn it into a match.  If there is
   no matching entry in the dirs section, raise [No_matching_dir] exception. *)
val of_dirspace : Dirs.t -> Terrat_change.Dirspace.t -> t option

(** Merge to lists of matches, deduplicating them.  In the case of duplicates,
   the first entry is taking. *)
val merge_with_dedup : t list -> t list -> t list

val match_tag_query : tag_query:Terrat_tag_set.t -> t -> bool
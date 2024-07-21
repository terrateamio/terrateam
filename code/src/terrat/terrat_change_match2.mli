type synthesize_config_err =
  [ `Bad_glob_err of string
  | `Depends_on_cycle_err of Terrat_dirspace.t list
  ]
[@@deriving show]

module Ctx : sig
  type t

  val make : dest_branch:string -> branch:string -> unit -> t
end

module Index : sig
  module Dep : sig
    type t = Module of string
  end

  type t

  val empty : t
  val make : symlinks:(string * string) list -> (string * Dep.t list) list -> t
end

module Dirspace_config : sig
  type t = {
    dirspace : Terrat_change.Dirspace.t;
    file_pattern_matcher : string -> bool;
    tags : Terrat_tag_set.t;
    when_modified : Terrat_base_repo_config_v1.When_modified.t;
  }
  [@@deriving show]
end

module Config : sig
  type t [@@deriving show]
end

val synthesize_config :
  ctx:Ctx.t ->
  index:Index.t ->
  file_list:string list ->
  Terrat_base_repo_config_v1.t ->
  (Config.t, [> synthesize_config_err ]) result

(** Given a config and a diff, find all dirspace configs that match the diff and
return them in layers, in order of which can be executed. [force_matches] will
insert specific matches into the output.  This is useful if there are some
matches which are required for reasons outside of the diff list *)
val match_diff_list :
  ?force_matches:Dirspace_config.t list ->
  Config.t ->
  Terrat_change.Diff.t list ->
  Dirspace_config.t list list

val of_dirspace : Config.t -> Terrat_dirspace.t -> Dirspace_config.t option
val merge_with_dedup : Dirspace_config.t list -> Dirspace_config.t list -> Dirspace_config.t list
val match_tag_query : tag_query:Terrat_tag_query.t -> Dirspace_config.t -> bool

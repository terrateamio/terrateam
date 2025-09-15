module Ctx : sig
  type t

  (** [working_dirspace] is the dirspace that is currently being evaluated. This is necessary to use
      [relative_dir] in the tag query. *)
  val make : ?working_dirspace:Terrat_dirspace.t -> dirspace:Terrat_dirspace.t -> unit -> t
end

type t [@@deriving show, eq]

val of_string : string -> (t, [> Terrat_tag_query_ast.err ]) result
val to_string : t -> string

(** [dirspace] is used in tests against the [dir] and [workspace] and [in dir] tests. *)
val match_ : ctx:Ctx.t -> tag_set:Terrat_tag_set.t -> t -> bool

(** A pre-defined matcher that matches anything, equivalent to [of_string ""] *)
val any : t

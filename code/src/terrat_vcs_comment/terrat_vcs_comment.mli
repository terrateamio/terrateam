module Strategy : sig
  type t =
    | Append
    | Delete
    | Minimize
  [@@deriving ord, show]
end

(** Primitive operations *)
module type S = sig
  (** Contains DB connection, API-related data, whatever 
      we need to communicate with external systems *)
  type t

  (** Corresponds to the actual content of an output like
      workspaces, dirspaces, metadata, etc. *)
  type el [@@deriving ord, show]

  (** The Id that we are going to get from the VCS, on
      GitHub this is an uint64. *)
  type comment_id [@@deriving ord, show]

  (** DB/Persistence operations *)
  val query_comment_id : t -> el -> (comment_id option, [> `Error ]) result Abb.Future.t

  val query_els_for_comment_id : t -> comment_id -> (el list, [> `Error ]) result Abb.Future.t

  val upsert_comment_id : t -> el list -> comment_id -> (unit, [> `Error ]) result Abb.Future.t

  (** Modify existing comments from a VCS provider *)
  val delete_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t

  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t

  (** Element primitives *)
  val rendered_length : t -> el list -> int
  val strategy : el -> Strategy.t
  (** When an el is too big to fit in a comment, compact formats it in a
      way that redirects people to our UI. Instead of working within the 
      limitations of certain version control systems. *)
  val compact : el -> el

  (** Constraints *)
  val max_comment_length : int
end

module Make (M : S) : sig
  (* raw input, raw string, intermediary type *)
  val run : M.t -> M.el list -> (unit, [> `Error ]) result Abb.Future.t
end

module Strategy : sig
  type t =
    | Append
    | Delete
    | Minimize
end

(** Primitives operations *)
module type S = sig
  (** Contains DB connections, API stuff, whatever we need to communicate with external systems *)
  type t

  (** Corresponds to the actual content of the comment: workspaces, metadata, comment status. *)
  type el

  type comment_id

  (** DB/Persistence operations *)
  val query_comment_id : t -> el -> (comment_id option, [> `Error ]) result Abb.Future.t

  val upsert_comment_id : t -> el list -> comment_id -> (unit, [> `Error ]) result Abb.Future.t

  (** Modify existing comments from a VCS provider *)
  val delete_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t

  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t
  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t

  (** Constraints *)
  val rendered_length : el -> int

  val max_comment_length : int
  val strategy : t -> el -> (Strategy.t, [> `Error ]) result Abb.Future.t
end

module Make (M : S) : sig
  (* raw input, raw string, intermediary type *)
  val run : M.t -> M.el list -> (unit, [> `Error ]) result Abb.Future.t
end

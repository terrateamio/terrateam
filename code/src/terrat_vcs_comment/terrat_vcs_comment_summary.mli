type tf_stats = {
  created : int;
  updated : int;
  deleted : int;
  replaced : int;
}
[@@deriving ord, show]

module type S = sig
  (** Contains DB connection, API-related data, whatever we need to communicate with external
      systems *)
  type t

  (** Summary elements *)
  type el [@@deriving ord, show]

  (** The Id that we are going to get from the VCS, on GitHub this is an uint64. *)
  type comment_id [@@deriving ord, show]

  (** DB/Persistence operations for summary comments *)
  val query_comment_id :
    t -> pull_number:int64 -> repo:int64 -> (comment_id option, [> `Error ]) result Abb.Future.t

  val query_summary_elements :
    t -> pull_number:int64 -> repo:int64 -> (el list, [> `Error ]) result Abb.Future.t

  val upsert_summary :
    t -> comment_id -> pull_number:int64 -> repo:int64 -> (unit, [> `Error ]) result Abb.Future.t

  (** Modify existing comments from a VCS provider *)
  val minimize_comment : t -> comment_id -> (unit, [> `Error ]) result Abb.Future.t

  val post_comment : t -> el list -> (comment_id, [> `Error ]) result Abb.Future.t

  (** Element primitives *)
  val pull_request : t -> int64

  val rendered_length : t -> el list -> int
  val repo : t -> int64
  val repo_config : t -> Terrat_base_repo_config_v1.derived Terrat_base_repo_config_v1.t

  (** Constraints *)
  val max_comment_length : int
end

module Make (M : S) : sig
  val run : M.t -> (unit, [> `Error ]) result Abb.Future.t
end

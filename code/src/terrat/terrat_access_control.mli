type query_err =
  [ `Invalid_query of string
  | `Error
  ]
[@@deriving show]

type err = query_err [@@deriving show]

module Policy : sig
  type t = {
    tag_query : Terrat_tag_set.t;
    policy : string list;
  }
  [@@deriving show]
end

module R : sig
  module Deny : sig
    type t = {
      change_match : Terrat_change_match.t;
      policy : string list option;
    }
    [@@deriving show]
  end

  type t = {
    pass : Terrat_change_match.t list;
    deny : Deny.t list;
  }
  [@@deriving show]
end

module type S = sig
  type ctx

  val query : ctx -> string -> (bool, [> query_err ]) result Abb.Future.t
end

module Make (S : S) : sig
  (** Test if there is a repo config change and it passes the
      configuration. [true] is returned if there is no repo configuration change
      or there is and it passes the permissions check. *)
  val eval_repo_config :
    S.ctx -> string list -> Terrat_change.Diff.t list -> (bool, [> err ]) result Abb.Future.t

  (** Evaluate a policy and a list of changes.  Policies are evaluating in
      order, comparing to the first one that has a matching tag query.  The
      result partitions the passing and deny.  All input changes will be
      represented in these two.. *)
  val eval :
    S.ctx -> Policy.t list -> Terrat_change_match.t list -> (R.t, [> err ]) result Abb.Future.t

  val eval_match_list : S.ctx -> string list -> (bool, [> err ]) result Abb.Future.t
end
module Error : sig
  type 'a t =
    [ `Migration_err of 'a
    | `Consistency_err
    ]
end

module type S = sig
  type tx
  type 'a t
  type err

  val tx :
    'a t -> (tx t -> ('r, err Error.t) result Abb.Future.t) -> ('r, err Error.t) result Abb.Future.t

  val start_migration : tx t -> string -> unit Abb.Future.t
  val complete_migration : 'a t -> string -> unit Abb.Future.t
  val list_migrations : 'a t -> string list -> unit Abb.Future.t
  val get_migrations : tx t -> (string list, err) result Abb.Future.t
  val add_migration : tx t -> string -> (unit, err) result Abb.Future.t
end

module Make (M : S) : sig
  type err = M.err Error.t

  module Migration : sig
    (** [`Async] means to run the returned migration outside of the transaction block. *)
    type 'a t =
      M.tx M.t ->
      ([ `Sync | `Async of 'a M.t -> (unit, M.err) result Abb.Future.t ], M.err) result Abb.Future.t
  end

  val run : 'a M.t -> (string * 'a Migration.t) list -> (unit, [> err ]) result Abb.Future.t
end

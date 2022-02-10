module type S = sig
  type t
  type err

  val start_migration : t -> string -> unit Abb.Future.t
  val complete_migration : t -> string -> unit Abb.Future.t
  val list_migrations : t -> string list -> unit Abb.Future.t
  val get_migrations : t -> (string list, err) result Abb.Future.t
  val add_migration : t -> string -> (unit, err) result Abb.Future.t
end

module Make (M : S) : sig
  type err =
    [ `Migration_err of M.err
    | `Consistency_err
    ]

  module Migration : sig
    type t = M.t -> (unit, M.err) result Abb.Future.t
  end

  val run : M.t -> (string * Migration.t) list -> (unit, [> err ]) result Abb.Future.t
end

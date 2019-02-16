module type S = sig
  type t
  type err

  val get_schema_version : t -> (string option, err) result Abb.Future.t
  val set_schema_version : t -> name:string -> version:string -> (unit, err) result Abb.Future.t
end

module Migrate (M : S) : sig
  module Migration : sig
    type t = (M.t -> (unit, M.err) result Abb.Future.t)
  end

  val run : M.t -> (string * Migration.t) list -> (unit, M.err) result Abb.Future.t
end

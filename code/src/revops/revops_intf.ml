module type MONAD = sig
  type 'a t

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t
  val protect : f:(unit -> 'a t) -> finally:(unit -> unit t) -> 'a t
end

module type S = sig
  module M : MONAD

  module Oprev : sig
    type 'a t
    val make : (unit -> 'a M.t) -> ('a -> unit M.t) -> 'a t
  end

  module Revop : sig
    type 'a t
  end

  val doop : 'a Oprev.t -> 'a Revop.t M.t

  val undo : 'a Revop.t -> unit M.t

  val peek : 'a Revop.t -> 'a

  (*
   * Composes two oprevs. The order of evaluation on a doop of the result is the first
   * oprev is setup and then the second. The order of evaluation on an undo is the
   * second oprev is torn-down and then the first.
   *)
  val compose : introduce:('a -> 'b -> 'c M.t) ->
                eliminate_first:('c -> 'a M.t) ->
                eliminate_second:('c -> 'b M.t) ->
                first:'a Oprev.t ->
                second:'b Oprev.t ->
                'c Oprev.t

  val compose_tuple : 'a Oprev.t -> 'b Oprev.t -> ('a * 'b) Oprev.t

  (* Infix shorthand for compose tuple. *)
  val ( +* ) : 'a Oprev.t -> 'b Oprev.t -> ('a * 'b) Oprev.t

  (*
   * Runs a unit function in the context of an oprev.
   * 1. doop the oprev.
   * 2. Runs the unit function.
   * 3. undo the revop.
   * 4. Returns the value from the unit function.
   *)
  val run_in_context : 'a Oprev.t -> ('a -> 'b M.t) -> 'b M.t
end

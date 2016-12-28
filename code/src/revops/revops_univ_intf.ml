module type S = sig
  module R : Revops_intf.S

  module KeyOprev : sig
    type 'a t = 'a Univ_map.Key.t * 'a R.Oprev.t
  end

  (* A Univ_map revop that does nothing. *)
  val noop : Univ_map.t R.Oprev.t

  (* Extend a Univ_map revop with a 'a Revop. *)
  val extend : Univ_map.t R.Oprev.t ->
               'a KeyOprev.t ->
	       Univ_map.t R.Oprev.t

  (* Infix operator version of extend. *)
  val ( +> ) : Univ_map.t R.Oprev.t ->
	       'a KeyOprev.t ->
	       Univ_map.t R.Oprev.t

  (* Creates a Univ_map.Key.t with the opaque serializer. *)
  val key : string -> 'a Univ_map.Key.t
end

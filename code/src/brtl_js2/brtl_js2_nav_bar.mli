module Choice : sig
  type 'a t

  val create : value:'a -> Brtl_js2.Brr.El.t list -> string -> 'a t
end

val run :
  eq:('a -> 'a -> bool) ->
  choices:'a Choice.t list ->
  'a Brtl_js2_rtng.Route.t list ->
  'b Brtl_js2.State.t ->
  Brtl_js2.Brr.El.t list Brtl_js2.Note.S.t

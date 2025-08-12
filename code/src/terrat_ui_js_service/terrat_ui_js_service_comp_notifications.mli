module Notice : sig
  type t

  val make : ?timeout:Duration.t -> msg:Brtl_js2.Brr.El.t list -> unit -> t
  val msg : t -> Brtl_js2.Brr.El.t list
  val timestamp : t -> Brtl_js2_datetime.t
  val msg_success : Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list
end

val make : unit -> Notice.t Brtl_js2.Note.event * Notice.t Brtl_js2.Note.E.send
val run : Notice.t Brtl_js2.Note.event Brtl_js2.Comp.t

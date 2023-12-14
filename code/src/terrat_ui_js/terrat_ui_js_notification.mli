type t

val make : ?timeout:Duration.t -> msg:Brtl_js2.Brr.El.t list -> unit -> t
val msg : t -> Brtl_js2.Brr.El.t list
val timestamp : t -> Brtl_js2_datetime.t
val msg_success : Brtl_js2.Brr.El.t list -> Brtl_js2.Brr.El.t list

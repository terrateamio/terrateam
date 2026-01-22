module Config : sig
  type t

  val make :
    ?remote_ip_header:string -> ?metrics:(Uri.t -> Cohttp.Code.meth -> float -> unit) -> unit -> t
end

val create : Config.t -> Brtl_mw.Mw.t

module Config : sig
  type t = { remote_ip_header : string option }
end

val create : Config.t -> Brtl_mw.Mw.t

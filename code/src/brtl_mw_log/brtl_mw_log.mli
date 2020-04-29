module Config : sig
  type t = {
    remote_ip_header : string option;
    extra_key : (string, Brtl_rspnc.t) Brtl_ctx.t -> string option;
  }
end

val create : Config.t -> Brtl_mw.Mw.t

module Make(Abb : Abb_intf.S with type Native.t = Unix.file_descr) : sig
  module Cfg : module type of Brtl_cfg.Make(Abb)
  module Ctx : module type of Brtl_ctx.Make(Abb)
  module Mw : module type of Brtl_mw.Make(Abb)
  module Rspnc : module type of Brtl_rspnc.Make(Abb)
  module Rtng : module type of Brtl_rtng.Make(Abb)
  module Tmpl : module type of Brtl_tmpl

  val run : Cfg.t -> Mw.t -> Rtng.t -> unit Abb.Future.t
end

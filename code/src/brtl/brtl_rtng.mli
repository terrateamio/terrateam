module Make(Abb : Abb_intf.S) : sig
  module Handler : sig
    type t = ((string, unit) Brtl_ctx.Make(Abb).t ->
              (string, Brtl_rspnc.Make(Abb).t) Brtl_ctx.Make(Abb).t Abb.Future.t)
  end

  module Route : sig
    include module type of Furl
    include module type of Furl_capture
  end

  module Method : sig
    type t = Cohttp.Code.meth
  end

  type t

  val create :
    default:Handler.t ->
    (Method.t * Handler.t Route.route) list ->
    t

  val route : ('a, 'b) Brtl_ctx.Make(Abb).t -> t -> Handler.t
end

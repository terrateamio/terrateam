type create_err = [ `Error ] [@@deriving show]

module Make (Vcs : Terrat_ui_js_service_vcs.S) : sig
  type 'a t

  val vcs : 'a t -> Vcs.t
  val create : Vcs.t -> (unit t, [> create_err ]) result Abb_js.Future.t
  val run : unit t Brtl_js2.Comp.t
end

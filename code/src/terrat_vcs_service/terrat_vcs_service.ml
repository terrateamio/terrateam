type start_err = [ `Error ] [@@deriving show]
type get_user_err = [ `Error ] [@@deriving show]

module type S = sig
  module Service : sig
    type t
    type vcs_config

    val name : t -> string

    val start :
      Terrat_config.t -> vcs_config -> Terrat_storage.t -> (t, [> start_err ]) result Abb.Future.t

    val stop : t -> unit Abb.Future.t
    val routes : t -> (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
    val get_user : t -> Uuidm.t -> (Terrat_user.t option, [> get_user_err ]) result Abb.Future.t
  end
end

type service = Service : (module S with type Service.t = 'a) * 'a -> service

(** The config service: {!Sgs_config.t} as a service in the manager, found with [Sgs_svc_mngr.get].
    [Make] builds the registrable service, which creates the config itself from the environment;
    consumers load the value with [Sgs_svc_mngr.load]. It has no routes and nothing to stop. *)

type t = Sgs_config.t

(** Names this service in a match on {!Sgs_service.ty}. *)
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

val name : string

(** The registrable config service: its start creates the config. A config that does not load
    refuses the start with [`Start_fatal_err]. *)
module Make (_ : Sgs_cloud.S) :
  Sgs_service.S with type t = Sgs_config.t and type opt = Sgs_svc_mngr.t

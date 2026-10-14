(** The terrat config service: {!Terrat_config.t} as a service in the manager. Its start reads the
    config from the Stategraph environment ({!Sgs_terrat_config.create}). A config that fails to
    load refuses the start, and the manager retries it. It has no routes and nothing to stop. *)

include Sgs_service.S with type t = Terrat_config.t and type opt = Sgs_svc_mngr.t

(** Names this service in a match on {!Sgs_service.ty}. *)
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

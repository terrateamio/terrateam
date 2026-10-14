(** The terrat storage service: {!Terrat_storage.t}, the pool of the terrateam database, as a
    service in the manager. Its start creates the pool from the terrat config service, so it refuses
    with [`Start_missing_deps_err] until that service is up, and with [`Start_err] when the database
    does not answer. It has no routes and nothing to stop. *)

include Sgs_service.S with type t = Terrat_storage.t and type opt = Sgs_svc_mngr.t

(** Names this service in a match on {!Sgs_service.ty}. *)
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

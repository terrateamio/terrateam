(** The terrat executor service: the executor of the event evaluator as a service in the manager.
    Its start creates the executor with the number of slots of the terrat config service, so it
    refuses with [`Start_missing_deps_err] until that service is up. It has no routes and nothing to
    stop. *)

include Sgs_service.S with type t = Terrat_vcs_event_evaluator2.Exec.t and type opt = Sgs_svc_mngr.t

(** Names this service in a match on {!Sgs_service.ty}. *)
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

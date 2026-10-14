(** Terrat's VCS services (GitHub, GitLab) as stategraph services. A VCS service serves the routes
    of its VCS and runs its hourly work (drift, cleanups). Its start loads the terrat config,
    storage and executor services, so it refuses with [`Start_missing_deps_err] until they are up. A
    VCS that the terrat config does not configure starts with no routes and no work. The routes are
    those of {!Terrat_vcs_service.S}, unchanged: the server that serves them adds the session
    middleware. *)

(** What tells one VCS from another. *)
module type SELECT = sig
  type vcs_config

  (** The name of the service. *)
  val name : string

  (** The config of this VCS in the terrat config, [None] when the VCS is not configured. *)
  val vcs_config : Terrat_config.t -> vcs_config option
end

(** GitHub, configured by the GitHub App of the environment only: an App that the console stored in
    the database is not used. *)
module Github : SELECT with type vcs_config = Terrat_config.Github.t

(** GitLab. *)
module Gitlab : SELECT with type vcs_config = Terrat_config.Gitlab.t

module type S = sig
  include Sgs_service.S with type opt = Sgs_svc_mngr.t

  (** Names this service in a match on {!Sgs_service.ty}. *)
  type 'a Sgs_service.ty += Ty : t Sgs_service.ty

  (** The started VCS service, [None] when the VCS is not configured. *)
  val service : t -> Terrat_vcs_service.service option
end

module Make
    (Vcs : Terrat_vcs_service.S)
    (_ : SELECT with type vcs_config = Vcs.Service.vcs_config) : S

module Make_github
    (_ : Terrat_vcs_service.S with type Service.vcs_config = Terrat_config.Github.t) : S

module Make_gitlab
    (_ : Terrat_vcs_service.S with type Service.vcs_config = Terrat_config.Gitlab.t) : S

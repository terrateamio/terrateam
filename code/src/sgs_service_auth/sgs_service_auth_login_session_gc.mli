(** Scheduler handler for the singleton ['gc_expired_login_sessions'] schedule: it deletes every
    login session row whose expiration has passed and logs how many it deleted. An expired row no
    longer authorizes anything, so this is garbage collection only. Never raises and never returns
    an error: a failure is logged. *)
val run : Sgs_config.t -> Sgs_storage.t -> Pgsql_io.t -> Yojson.Safe.t -> unit Abb.Future.t

(** The task id this handler runs under; the [kind] of its schedule row. *)
val kind : string

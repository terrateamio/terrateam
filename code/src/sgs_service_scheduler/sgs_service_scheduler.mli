(** The scheduler service: a distributed scheduler for sgs tasks, backed by the [schedules] table.

    Multiple scheduler services may run concurrently against the same database and coordinate
    {b only} through Postgres. On each iteration a due schedule is claimed with
    [select ... for update skip locked] inside a transaction, dispatched, and its [last_run_at]
    advanced before the transaction commits, guaranteeing that each due occurrence runs on exactly
    one instance.

    A schedule is due when [now() > last_run_at + interval(schedule)] where [schedule] is one of
    [hourly], [daily], [weekly], [monthly]. A claim is dispatched to the task registered for its
    kind; a claim with nobody registered records a miss, runs again on its next schedule, and is
    deleted at three misses. Every operation is logged with context.

    The service adds no routes. *)

type register_kind_err = [ `Chan_closed ] [@@deriving show]
type register_task_err = [ `Chan_closed ] [@@deriving show]

module Id : sig
  type t

  val of_string : string -> t
  val to_string : t -> string
end

module Schedule : sig
  type t =
    | Minutely
    | Hourly
    | Daily
    | Weekly
    | Monthly
end

include Sgs_service.S with type opt = Sgs_svc_mngr.t

(** Names this service in a match on {!Sgs_service.ty}. *)
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

(** [start_with_wait ~wait config storage] starts the scheduler, forking its service loop. [wait] is
    called between iterations and determines the cadence; {!start} uses the default of sleeping ten
    minutes. Tests pass a short or one-shot [wait] to drive iterations deterministically. *)
val start_with_wait :
  wait:(unit -> unit Abb.Future.t) -> Sgs_config.t -> Sgs_storage.t -> t Abb.Future.t

(** Register a task with the scheduler. The task is identified by its id, and it is stored with its
    schedule. Arbitrary JSON data can be included in the task. The function passed in is run when
    the task is triggered.

    If a task in the database and triggered but no task is registered via a [register_kind]
    function, the task is run again on its next schedule. After three iterations of this, the task
    is delete from the database.

    At startup, services register their tasks with the scheduler. They are upserted with tasks in
    the database. A task that is not registered anymore will eventually be deleted. *)
val register_kind :
  t ->
  kind:Id.t ->
  (Sgs_config.t -> Sgs_storage.t -> Pgsql_io.t -> Yojson.Safe.t -> unit Abb.Future.t) ->
  (unit, [> register_kind_err ]) result Abb.Future.t

(** Register a task of a particular kind and attach the data to each run. *)
val register_task :
  t ->
  kind:Id.t ->
  Schedule.t ->
  Yojson.Safe.t ->
  (unit, [> register_task_err ]) result Abb.Future.t

(** [register_scheduled_kind t ~kind schedule run] registers [run] as the handler of [kind] and
    upserts the one row of [kind], with no data, on [schedule]. A closed registry is logged and
    skipped: a service does not fail its start for it. *)
val register_scheduled_kind :
  t ->
  kind:Id.t ->
  Schedule.t ->
  (Sgs_config.t -> Sgs_storage.t -> Pgsql_io.t -> Yojson.Safe.t -> unit Abb.Future.t) ->
  unit Abb.Future.t

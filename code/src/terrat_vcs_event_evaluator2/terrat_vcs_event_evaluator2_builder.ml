module Irm = Abbs_future_combinators.Infix_result_monad
module Serializer = Abb_service_serializer.Make (Abb.Future)

module Make (S : Terrat_vcs_provider2.S) = struct
  module Logs' = Logs

  (* General logger *)
  let src = Logs.Src.create ("vcs_event_evaluator2_builder." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)

  (* Specific logger for run_db *)
  let src_run_db = Logs'.Src.create ("vcs_event_evaluator2_builder." ^ S.name ^ ".run_db")

  module Logs_run_db = (val Logs'.src_log src_run_db : Logs'.LOG)

  (* Targets/keys *)
  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap

  type err = Keys.err [@@deriving show]

  module B = struct
    module Key_repr = struct
      type t = string [@@deriving eq]

      let to_string = CCFun.id
    end

    type 'v k = 'v Hmap.key

    let key_repr_of_key = Hmap.Key.info

    module C = struct
      type 'a t = 'a Abb.Future.t

      let return v = Abb.Future.return v
      let ( >>= ) = Abb.Future.Infix_monad.( >>= )

      let protect f =
        let open Abb.Future.Infix_monad in
        (* Wrap ret in another deferred so that it can be unwrapped with (>>=) *)
        f () >>= fun ret -> Abb.Future.return (Abb.Future.return ret)
    end

    module Notify = struct
      type t = (unit Abb.Future.t * unit Abb.Future.Promise.t) ref

      let create () =
        let p = Abb.Future.Promise.create () in
        let fut = Abb.Future.Promise.future p in
        ref (fut, p)

      let notify t =
        let open Abb.Future.Infix_monad in
        let _, notify = !t in
        let p = Abb.Future.Promise.create () in
        let fut = Abb.Future.Promise.future p in
        t := (fut, p);
        Abb.Future.Promise.set notify () >>= fun () -> Abb.Future.return ()

      let wait t =
        let open Abb.Future.Infix_monad in
        let wait, _ = !t in
        wait >>= fun () -> Abb.Future.return ()
    end

    module State = struct
      type t = {
        log_id : string;
        config : S.Api.Config.t;
        db : Pgsql_io.t Serializer.Mutex.t;
        orig_store : Hmap.t;
        tasks : Hmap.t;
        mutable store : Hmap.t;
        mutable dirty : Key_repr.t list;
      }

      let set_k t k v =
        t.store <- Hmap.add k v t.store;
        Abb.Future.return ()

      let get_k t k =
        match Hmap.find k t.store with
        | Some v -> Abb.Future.return v
        | None -> raise (Failure ("Missing_dep_err " ^ Hmap.Key.info k))

      let get_k_opt t k = Abb.Future.return (Hmap.find k t.store)
    end
  end

  module Bs = Buildsys.Make (B)

  let rebuilder =
    {
      Bs.Rebuilder.run =
        (fun s k _v ->
          let is_dirty = CCList.mem ~eq:B.Key_repr.equal (B.key_repr_of_key k) s.B.State.dirty in
          if is_dirty then
            s.B.State.dirty <-
              CCList.filter CCFun.(B.Key_repr.equal (B.key_repr_of_key k) %> not) s.B.State.dirty;
          Abb.Future.return is_dirty);
    }

  module State = struct
    type t = B.State.t

    let make ~log_id ~store ~config ~db ~tasks () =
      let open Abb.Future.Infix_monad in
      Serializer.create ()
      >>= fun serializer ->
      let db = Serializer.Mutex.create serializer db in
      Abb.Future.return { B.State.log_id; config; orig_store = store; tasks; store; dirty = []; db }

    let set_log_id log_id t = { t with B.State.log_id }
    let config t = t.B.State.config
    let mark_dirty t k = t.B.State.dirty <- B.key_repr_of_key k :: t.B.State.dirty
    let orig_store t = t.B.State.orig_store
    let set_orig_store store t = { t with B.State.store; orig_store = store }
    let tasks t = t.B.State.tasks
    let set_tasks tasks t = { t with B.State.tasks }

    let forward_store_value k t m =
      match Hmap.find k t.B.State.store with
      | Some v -> Hmap.add k v m
      | None -> m
  end

  external coerce_to_task : 'a B.k -> 'a Bs.Task.t B.k = "%identity"

  let log_id state = state.B.State.log_id

  let mk_log_id ~request_id job_id =
    Uuidm.to_string job_id ^ "." ^ CCString.take 5 @@ Digest.to_hex @@ Digest.string request_id

  let run_db s ~f =
    let open Abb.Future.Infix_monad in
    Serializer.Mutex.run s.B.State.db ~f:(fun db ->
        Abbs_future_combinators.with_finally
          (fun () ->
            Logs_run_db.info (fun m ->
                m
                  "%s : DATABASE : MUTEX : ENTER : conn=%s"
                  (log_id s)
                  (Uuidm.to_string @@ Pgsql_io.id db));
            f db)
          ~finally:(fun () ->
            Logs_run_db.info (fun m ->
                m
                  "%s : DATABASE : MUTEX : EXIT : conn=%s"
                  (log_id s)
                  (Uuidm.to_string @@ Pgsql_io.id db));
            Abb.Future.return ()))
    >>= function
    | `Ok (Ok v) -> Abb.Future.return (Ok v)
    | `Ok (Error err) -> Abb.Future.return (Error err)
    | `Closed -> Abb.Future.return (Error `Closed)

  let make_tasks tasks_map =
    { Bs.Tasks.get = (fun s k -> Abb.Future.return (Hmap.find (coerce_to_task k) tasks_map)) }

  let eval s k =
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m ->
            m "%s : BUILDER : EVAL : END : target=%s : time=%f" (log_id s) (Hmap.Key.info k) t))
      (fun () ->
        Logs.info (fun m ->
            m "%s : BUILDER : EVAL : START : target=%s" (log_id s) (Hmap.Key.info k));
        Bs.build
          rebuilder
          (make_tasks s.B.State.tasks)
          k
          (Bs.St.create { s with B.State.store = s.B.State.orig_store }))
end

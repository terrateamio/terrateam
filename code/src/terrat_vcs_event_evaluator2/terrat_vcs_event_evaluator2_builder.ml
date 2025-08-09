module Irm = Abbs_future_combinators.Infix_result_monad
module Serializer = Abb_service_serializer.Make (Abb.Future)

module Make (S : Terrat_vcs_provider2.S) = struct
  let src = Logs.Src.create ("vcs_event_evaluator2_builder." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Keys = Terrat_vcs_event_evaluator2_targets.Make (S)
  module Hmap = Keys.Hmap

  type repo_config_fetch_err = Terrat_vcs_provider2.fetch_repo_config_with_provenance_err
  [@@deriving show]

  type err =
    [ `Missing_dep_err of string
    | `Error
    | `Closed
    | repo_config_fetch_err
    | Terrat_change_match3.synthesize_config_err
    | `Suspend_eval_err of string
    | `Work_manifest_err of Uuidm.t
    | `Noop
    | Pgsql_io.err
    | Pgsql_pool.err
    | Str_template.err
    ]
  [@@deriving show]

  module B = struct
    module Key_repr = struct
      type t = Hmap.Key.t

      let equal = Hmap.Key.equal
    end

    type 'v k = 'v Hmap.key

    let key_repr_of_key = Hmap.Key.hide_type

    module C = struct
      type 'a t = ('a, err) result Abb.Future.t

      let return v = Abb.Future.return (Ok v)
      let ( >>= ) = Irm.( >>= )

      let protect f =
        let open Abb.Future.Infix_monad in
        (* Wrap ret in another deferred so that it can be unwrapped with (>>=) *)
        f () >>= fun ret -> Abb.Future.return (Ok (Abb.Future.return ret))
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
        Abb.Future.Promise.set notify () >>= fun () -> Abb.Future.return (Ok ())

      let wait t =
        let open Abb.Future.Infix_monad in
        let wait, _ = !t in
        wait >>= fun () -> Abb.Future.return (Ok ())
    end

    module State = struct
      type t = {
        log_id : string;
        config : S.Api.Config.t;
        db : Pgsql_io.t Serializer.Mutex.t;
        mutable store : Hmap.t;
        mutable dirty : Key_repr.t list;
      }

      let set_k t k v =
        t.store <- Hmap.add k v t.store;
        Abb.Future.return (Ok ())

      let get_k t k =
        match Hmap.find k t.store with
        | Some v -> Abb.Future.return (Ok v)
        | None -> Abb.Future.return (Error (`Missing_dep_err (Hmap.Key.info k)))

      let get_k_opt t k = Abb.Future.return (Ok (Hmap.find k t.store))
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
          Abb.Future.return (Ok is_dirty));
    }

  module State = struct
    type t = B.State.t

    let make ~log_id ~store ~config ~db () =
      let open Abb.Future.Infix_monad in
      Serializer.create ()
      >>= fun serializer ->
      let db = Serializer.Mutex.create serializer db in
      Abb.Future.return { B.State.log_id; config; store; dirty = []; db }

    let config t = t.B.State.config
    let mark_dirty t k = t.B.State.dirty <- B.key_repr_of_key k :: t.B.State.dirty
    let store t = t.B.State.store
  end

  external coerce_to_task : 'a B.k -> 'a Bs.Task.t B.k = "%identity"

  let union_tasks { Bs.Tasks.get = t1 } { Bs.Tasks.get = t2 } =
    {
      Bs.Tasks.get =
        (fun s k ->
          let open B.C in
          t1 s k
          >>= function
          | Some _ as r -> return r
          | None -> t2 s k);
    }

  let run_db s ~f =
    let open Abb.Future.Infix_monad in
    Serializer.Mutex.run s.B.State.db ~f
    >>= function
    | `Ok (Ok v) -> Abb.Future.return (Ok v)
    | `Ok (Error err) -> Abb.Future.return (Error err)
    | `Closed -> Abb.Future.return (Error `Closed)

  let log_id state = state.B.State.log_id
end

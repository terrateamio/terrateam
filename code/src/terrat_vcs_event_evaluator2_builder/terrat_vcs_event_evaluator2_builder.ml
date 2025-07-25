module Irm = Abbs_future_combinators.Infix_result_monad
module Serializer = Abb_service_serializer.Make (Abb.Future)

module Make (S : Terrat_vcs_provider2.S) = struct
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
        storage : Terrat_storage.t;
        db : Pgsql_io.t Serializer.Mutex.t;
        mutable store : Hmap.t;
      }

      let log_id t = t.log_id

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

  external coerce_to_task : 'a B.k -> 'a Bs.Task.t B.k = "%identity"

  let run_db s ~f =
    let open Abb.Future.Infix_monad in
    Serializer.Mutex.run s.B.State.db ~f
    >>= function
    | `Ok (Ok v) -> Abb.Future.return (Ok v)
    | `Ok (Error err) -> Abb.Future.return (Error err)
    | `Closed -> Abb.Future.return (Error `Closed)
end

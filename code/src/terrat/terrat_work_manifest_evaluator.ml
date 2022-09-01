module Dirspace_map = CCMap.Make (Terrat_change.Dirspace)

module Work_manifest = struct
  type 'a t = 'a Terrat_work_manifest.Existing.t
end

type ('pull_request, 'pull_request_lite) err =
  [ Pgsql_pool.err
  | Pgsql_io.err
  | `Work_manifest_not_found
  | `Work_manifest_already_run of ('pull_request Work_manifest.t[@opaque])
  | `Work_manifest_in_queue_state
  | `Dirspaces_without_valid_plans of Terrat_change.Dirspace.t list
  | `Dirspaces_owned_by_other_pull_requests of (Terrat_change.Dirspace.t * 'pull_request_lite) list
  | `Error
  ]
[@@deriving show]

module type S = sig
  type t

  module Pull_request : sig
    type t [@@deriving show]

    module Lite : sig
      type t [@@deriving show]
    end
  end

  val request_id : t -> string

  val initiate_work_manifest :
    Pgsql_io.t -> t -> (Pull_request.t Work_manifest.t option, [> `Error ]) result Abb.Future.t

  val query_dirspaces_without_valid_plans :
    Pgsql_io.t ->
    t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Terrat_change.Dirspace.t list, [> `Error ]) result Abb.Future.t

  val query_dirspaces_owned_by_other_pull_requests :
    Pgsql_io.t ->
    t ->
    Pull_request.t ->
    Terrat_change.Dirspace.t list ->
    (Pull_request.Lite.t Dirspace_map.t, [> `Error ]) result Abb.Future.t
end

type ('a, 'b) err' = ('a, 'b) err [@@deriving show]

module Make (S : S) = struct
  type err = (S.Pull_request.t, S.Pull_request.Lite.t) err' [@@deriving show]

  let run' storage t =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_pool.with_conn storage ~f:(fun db ->
        Pgsql_io.tx db ~f:(fun () ->
            Logs.info (fun m ->
                m "WORK_MANIFEST_EVALUATOR : %s : INITIATE_WORK_MANIFEST" (S.request_id t));
            S.initiate_work_manifest db t
            >>= function
            | None -> Abb.Future.return (Ok None)
            | Some
                (Terrat_work_manifest.{ state = State.(Completed | Aborted); pull_request; _ } as
                wm) -> Abb.Future.return (Error (`Work_manifest_already_run wm))
            | Some Terrat_work_manifest.{ state = State.Queued; _ } ->
                Abb.Future.return (Error `Work_manifest_in_queue_state)
            | Some work_manifest -> (
                match work_manifest.Terrat_work_manifest.run_type with
                | Terrat_work_manifest.Run_type.(Autoplan | Plan | Unsafe_apply) ->
                    Abb.Future.return (Ok (Some work_manifest))
                | Terrat_work_manifest.Run_type.(Autoapply | Apply) -> (
                    Logs.debug (fun m ->
                        m
                          "WORK_MANIFEST_EVALUATOR : %s : QUERY_DIRSPACES_OWNED_BY_OTHER_PR"
                          (S.request_id t));
                    S.query_dirspaces_owned_by_other_pull_requests
                      db
                      t
                      work_manifest.Terrat_work_manifest.pull_request
                      (CCList.map
                         Terrat_change.Dirspaceflow.to_dirspace
                         work_manifest.Terrat_work_manifest.changes)
                    >>= function
                    | owned_dirspaces when Dirspace_map.is_empty owned_dirspaces -> (
                        (* No dirspaces owned by another pull request, great *)
                        Logs.debug (fun m ->
                            m
                              "WORK_MANIFEST_EVALUATOR : %s : QUERY_DIRSPACES_WITHOUT_VALID_PLANS"
                              (S.request_id t));
                        S.query_dirspaces_without_valid_plans
                          db
                          t
                          work_manifest.Terrat_work_manifest.pull_request
                          (CCList.map
                             Terrat_change.Dirspaceflow.to_dirspace
                             work_manifest.Terrat_work_manifest.changes)
                        >>= function
                        | [] ->
                            (* All dirspaces have plans, great *)
                            Abb.Future.return (Ok (Some work_manifest))
                        | dirspaces ->
                            (* Some dirspaces do not have valid plans, not great *)
                            Abb.Future.return (Error (`Dirspaces_without_valid_plans dirspaces)))
                    | owned_dirspaces ->
                        (* Some dirspaces owned by other pull requests *)
                        Abb.Future.return
                          (Error
                             (`Dirspaces_owned_by_other_pull_requests
                               (Dirspace_map.to_list owned_dirspaces)))))))

  let run storage t =
    (run' storage t
      : (S.Pull_request.t Work_manifest.t option, err) result Abb.Future.t
      :> (S.Pull_request.t Work_manifest.t option, [> err ]) result Abb.Future.t)
end

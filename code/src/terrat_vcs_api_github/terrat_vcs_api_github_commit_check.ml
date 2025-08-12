let src = Logs.Src.create "vcs_api_github_commit_check"

module Logs = (val Logs.src_log src : Logs.LOG)
module String_map = CCMap.Make (CCString)

type err = Githubc2_abb.call_err [@@deriving show]

type list_err =
  [ err
  | `Commit_check_list_err of string
  ]
[@@deriving show]

let create ~owner ~repo ~ref_ ~checks client =
  Terrat_github.Commit_status.create
    ~owner
    ~repo
    ~sha:ref_
    ~creates:
      (CCList.map
         (fun Terrat_commit_check.{ details_url; description; title; status } ->
           Terrat_github.Commit_status.Create.T.make
             ~target_url:details_url
             ~description
             ~context:title
             ~state:
               Terrat_commit_check.Status.(
                 match status with
                 | Queued | Running -> "pending"
                 | Completed -> "success"
                 | Failed -> "failure"
                 | Canceled -> "failure")
             ())
         checks)
    client

let list_commit_statuses ~log_id ~owner ~repo ~sha client =
  Abbs_time_it.run
    (fun t -> Logs.info (fun m -> m "%s : LIST_COMMIT_STATUSES : %f" log_id t))
    (fun () -> Terrat_github.Commit_status.list ~owner ~repo ~sha client)

let list_status_checks ~log_id ~owner ~repo ~ref_ client =
  Abbs_time_it.run
    (fun t -> Logs.info (fun m -> m "%s : LIST_STATUS_CHECKS : %f" log_id t))
    (fun () -> Terrat_github.Status_check.list ~owner ~repo ~ref_ client)

let list ~log_id ~owner ~repo ~ref_ client =
  let open Abb.Future.Infix_monad in
  let module S = Githubc2_components.Status in
  Abbs_future_combinators.Infix_result_app.(
    (fun statuses checks -> (statuses, checks))
    <$> list_commit_statuses ~log_id ~owner ~repo ~sha:ref_ client
    <*> list_status_checks ~log_id ~owner ~repo ~ref_ client)
  >>= function
  | Ok (statuses, checks) ->
      let statuses =
        statuses
        |> CCList.sort
             (fun
               S.{ primary = Primary.{ created_at = c1; _ }; _ }
               S.{ primary = Primary.{ created_at = c2; _ }; _ }
             ->
               (* Sort commit statuses such that the most recently created is
                  first in the list.  This is necessary for later on when we
                  combine then and only take the first title. *)
               CCString.compare c2 c1)
        |> CCList.map
             (fun
               Githubc2_components.Status.
                 { primary = Primary.{ context; description; state; target_url; _ }; _ }
             ->
               Terrat_commit_check.(
                 make
                   ~details_url:(CCOption.get_or ~default:"" target_url)
                   ~description:(CCOption.get_or ~default:"" description)
                   ~title:context
                   ~status:
                     (match state with
                     | "error" | "failure" -> Status.Failed
                     | "pending" -> Status.Running
                     | "success" -> Status.Completed
                     | _ -> assert false)))
      in
      let checks =
        let module Check_run = Githubc2_components.Check_run in
        let module App = Githubc2_components.Nullable_integration in
        checks
        |> CCList.filter (function
             | Check_run.
                 {
                   primary =
                     Primary.
                       {
                         app = Some App.{ primary = Primary.{ slug = Some "github-actions"; _ }; _ };
                         _;
                       };
                   _;
                 } ->
                 (* We are filtering out checks from the github app because that
                      is metadata about running the action and not the action
                      output itself. *)
                 false
             | _ -> true)
        |> CCList.sort
             (fun
               Check_run.{ primary = Primary.{ completed_at = c1; _ }; _ }
               Check_run.{ primary = Primary.{ completed_at = c2; _ }; _ }
             ->
               (* Sort these with the most recently completed at the head of the
                  list.  This is necessary because later we'll take the first
                  matching by name. *)
               match (c1, c2) with
               | None, None -> 0
               | None, _ -> 1
               | _, None -> -1
               | Some s1, Some s2 -> CCString.compare s2 s1)
        |> CCList.map
             (fun Check_run.{ primary = Primary.{ name; details_url; status; conclusion; _ }; _ } ->
               Terrat_commit_check.(
                 make
                   ~details_url:(CCOption.get_or ~default:"" details_url)
                   ~description:name
                   ~title:name
                   ~status:
                     (match (status, conclusion) with
                     | "queued", _ -> Status.Queued
                     | "in_progress", _ -> Status.Running
                     | "completed", Some ("success" | "skipped" | "neutral") -> Status.Completed
                     | "completed", Some ("failure" | "cancelled" | "timed_out" | "action_required")
                       -> Status.Failed
                     | "completed", Some v ->
                         raise (Failure ("Unknown status check conclusion value: " ^ v))
                     | "completed", None -> raise (Failure "None conclusion")
                     | _, _ -> assert false)))
      in
      let all_unique_checks =
        statuses @ checks
        |> CCListLabels.fold_left
             ~init:String_map.empty
             ~f:(fun acc (Terrat_commit_check.{ title; _ } as cc) ->
               (* Both API calls return duplicate statuses, but it's the most
                  recent one (by timestamp) that we want.  We have sorted them
                  by timestamp earlier and now we just take the first status
                  check found by name.  The assumption here is that the most
                  recent run by name is the true status of the run. *)
               if not (String_map.mem title acc) then String_map.add title cc acc else acc)
        |> String_map.values
        |> Iter.to_list
      in
      Abb.Future.return (Ok all_unique_checks)
  | Error #Githubc2_abb.call_err as err -> Abb.Future.return err
  | Error (#Terrat_github.Commit_status.list_err as err) ->
      Abb.Future.return
        (Error (`Commit_check_list_err (Terrat_github.Commit_status.show_list_err err)))

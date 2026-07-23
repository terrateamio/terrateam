module Metrics = struct
  module Task_exec_duration = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_list [ 0.0; 1.0; 2.0; 5.0; 10.0; 20.0; 50.0; 100.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "vcs_event_evaluator2_task_base"

  let exec_duration =
    let help = "Time scheduler spends processing a task." in
    Task_exec_duration.v_label ~label_name:"task" ~help ~namespace ~subsystem "exec_duration"
end

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_tasks_base." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)

  let run ~name f path s fetcher =
    Abb.Future.await_bind (function
      | `Det r -> Abb.Future.return r
      | `Exn (Buildsys.Error.Fetch_cycle_exn exn, bt_opt) ->
          Logs.err (fun m -> m "%s : %a" (Builder.log_id s) Buildsys.Error.pp exn);
          CCOption.iter
            (fun bt ->
              Logs.err (fun m ->
                  m "%s : BACKTRACE: %s" (Builder.log_id s) (Printexc.raw_backtrace_to_string bt)))
            bt_opt;
          Abb.Future.return (Error `Error)
      | `Exn (exn, bt_opt) ->
          Logs.err (fun m -> m "%s : %s" (Builder.log_id s) (Printexc.to_string exn));
          CCOption.iter
            (fun bt ->
              Logs.err (fun m ->
                  m "%s : BACKTRACE: %s" (Builder.log_id s) (Printexc.raw_backtrace_to_string bt)))
            bt_opt;
          Abb.Future.return (Error `Error)
      | `Aborted ->
          Logs.err (fun m -> m "%s : ABORTED" (Builder.log_id s));
          Abb.Future.return (Error `Error))
    @@ Abbs_time_it.run'
         (fun ret t ->
           Metrics.Task_exec_duration.observe (Metrics.exec_duration name) t;
           match ret with
           | Ok _ ->
               Logs.info (fun m ->
                   m "%s : TASK : END : SUCCESS : name=%s : time=%f" (Builder.log_id s) name t)
           | Error (`Suspend_eval _) ->
               Logs.info (fun m ->
                   m "%s : TASK : END: SUSPEND : name=%s : time=%f" (Builder.log_id s) name t)
           | Error `Noop ->
               Logs.info (fun m ->
                   m "%s : TASK : END: NOOP : name=%s : time=%f" (Builder.log_id s) name t)
           | Error #Builder.err ->
               Logs.info (fun m ->
                   m "%s : TASK : END: FAIL : name=%s : time=%f" (Builder.log_id s) name t))
         (fun () ->
           Logs.info (fun m ->
               m
                 "%s : TASK : START : name=%s : path=[%s]"
                 (Builder.log_id s)
                 name
                 (CCString.concat ", " path));
           f (Builder.State.set_path path s) fetcher)

  let forward_std_keys s store = store |> Builder.State.forward_store_value Keys.pull_request s
end

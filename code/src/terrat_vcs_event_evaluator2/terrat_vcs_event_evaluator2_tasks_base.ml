module Fc = Abbs_future_combinators
module Irm = Abbs_future_combinators.Infix_result_monad
module Tjc = Terrat_job_context
module Msg = Terrat_vcs_provider2.Msg
module P2 = Terrat_vcs_provider2

module Make
    (S : Terrat_vcs_provider2.S)
    (Keys : module type of Terrat_vcs_event_evaluator2_targets.Make (S)) =
struct
  let src = Logs.Src.create ("vcs_event_evaluator2_tasks_base." ^ S.name)

  module Logs = (val Logs.src_log src : Logs.LOG)
  module Wm_sm = Terrat_vcs_event_evaluator2_wm_sm.Make (S) (Keys)
  module Repo_tree_wm = Terrat_vcs_event_evaluator2_wm_sm_repo_tree.Make (S) (Keys)
  module Build_config_wm = Terrat_vcs_event_evaluator2_wm_sm_build_config.Make (S) (Keys)
  module Indexer_wm = Terrat_vcs_event_evaluator2_wm_sm_indexer.Make (S) (Keys)
  module Tf_op_wm = Terrat_vcs_event_evaluator2_wm_sm_tf_op.Make (S) (Keys)
  module Access_control = Terrat_vcs_event_evaluator2_access_control.Make (S) (Keys)
  module Hmap = Keys.Hmap
  module Builder = Terrat_vcs_event_evaluator2_builder.Make (S)
  module B = Builder.B
  module Bs = Builder.Bs
  module Tasks = struct end

  let run ~name f path s fetcher =
    Abbs_time_it.run
      (fun t ->
        Logs.info (fun m -> m "%s : TASK : END : name=%s : time=%f" (Builder.log_id s) name t))
      (fun () ->
        let open Abb.Future.Infix_monad in
        Logs.info (fun m ->
            m
              "%s : TASK : START : name=%s : path=[%s]"
              (Builder.log_id s)
              name
              (CCString.concat ", " path));
        f s fetcher
        >>= function
        | Ok _ as r -> Abb.Future.return r
        | Error (`Suspend_eval _) as err ->
            Logs.info (fun m -> m "%s : TASK : SUSPEND : name=%s" (Builder.log_id s) name);
            Abb.Future.return err
        | Error (`Noop as err) ->
            Logs.info (fun m -> m "%s : TASK : NOOP : name=%s" (Builder.log_id s) name);
            Abb.Future.return (Error err)
        | Error (#Builder.err as err) ->
            Logs.info (fun m -> m "%s : TASK : FAIL : name=%s" (Builder.log_id s) name);
            Abb.Future.return (Error err))

  let default_tasks () =
    let coerce = Builder.coerce_to_task in
    Hmap.empty
end

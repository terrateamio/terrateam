let one_day = 60.0 *. 60.0 *. 24.0

let rec start storage =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.ignore
    Terrat_github_evaluator2.Event.Plan_cleanup.(eval (make ~request_id:"PLAN_CLEANUP" ~storage ()))
  >>= fun () -> Abb.Sys.sleep one_day >>= fun () -> start storage

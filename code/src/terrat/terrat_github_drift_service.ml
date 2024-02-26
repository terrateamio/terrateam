let one_hour = 60.0 *. 60.0

let rec start config storage =
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.ignore
    Terrat_github_evaluator2.Event.Drift.(eval (make ~config ~request_id:"DRIFT" ~storage ()))
  >>= fun () ->
  Abbs_future_combinators.ignore
    Terrat_github_evaluator2.Runner.(eval (make ~config ~request_id:"DRIFT" ~storage ()))
  >>= fun () -> Abb.Sys.sleep one_hour >>= fun () -> start config storage

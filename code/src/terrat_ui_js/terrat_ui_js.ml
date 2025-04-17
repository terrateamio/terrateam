module Github_service = Terrat_ui_js_service.Make (Terrat_ui_js_service_github)

let main_comp services state =
  let open Abb_js.Future.Infix_monad in
  let rec run = function
    | Terrat_ui_js_service.Service ((module M), s) :: services -> (
        M.is_logged_in s
        >>= function
        | Ok _ -> M.Comp.Main.run (Brtl_js2.State.with_app_state s state)
        | Error _ -> run services)
    | [] -> Abb_js.Future.return (Brtl_js2.Output.navigate (Uri.of_string "/login"))
  in
  run services

let init state =
  let run =
    let open Abb_js_future_combinators.Infix_result_monad in
    let login_rt () = Brtl_js2_rtng.(root "" / "login") in
    let logout_rt () = Brtl_js2_rtng.(root "" / "logout") in
    let main_rt () = Brtl_js2_rtng.(root "") in
    Github_service.create ()
    >>= fun github ->
    let services = [ Terrat_ui_js_service.Service ((module Github_service), github) ] in
    ignore
      (Brtl_js2.Router_output.create
         state
         (Brtl_js2.Brr.Document.body Brtl_js2.Brr.G.document)
         Brtl_js2_rtng.
           [
             login_rt () --> Terrat_ui_js_comp_login.run services;
             logout_rt () --> Terrat_ui_js_comp_logout.run;
             main_rt () --> main_comp services;
           ]);
    Abb_js.Future.return (Ok ())
  in
  let open Abb_js.Future.Infix_monad in
  run
  >>= function
  | Ok () -> Abb_js.Future.return ()
  | Error err ->
      Brtl_js2.Brr.Console.(log [ err ]);
      assert false

let () = Brtl_js2.main (Terrat_ui_js_client.create ()) init

let new_installation_install installation_id state =
  Abb_js.Future.return
    (Brtl_js2.Output.navigate (Uri.of_string ("/i/" ^ installation_id ^ "/repos/refresh")))

let no_installation state =
  let open Abb_js.Future.Infix_monad in
  let consumed_path = Brtl_js2.State.consumed_path state in
  let client = Brtl_js2.State.app_state state in
  Terrat_ui_js_client.whoami client
  >>= function
  | Ok (Some _) -> (
      let module R = Terrat_api_user.List_installations.Responses.OK in
      Terrat_ui_js_client.installations client
      >>= function
      | Ok R.{ installations = [] } ->
          Abb_js.Future.return
            (Brtl_js2.Output.navigate (Uri.of_string "https://github.com/apps/terrateam-action"))
      | Ok R.{ installations = i :: _ } ->
          let module I = Terrat_api_components.Installation in
          Abb_js.Future.return
            (Brtl_js2.Output.navigate (Uri.of_string (consumed_path ^ "/i/" ^ i.I.id)))
      | Error _ -> failwith "nyi2")
  | Ok None -> Abb_js.Future.return (Brtl_js2.Output.navigate (Uri.of_string "/login"))
  | Error _ -> assert false

let init state =
  let login_rt () = Brtl_js2_rtng.(root "" / "login") in
  let main_rt () = Brtl_js2_rtng.(root "" / "i" /% Path.string) in
  let installation_install_rt () = Brtl_js2_rtng.(root "" /? Query.string "installation_id") in
  let no_installation_rt () = Brtl_js2_rtng.(root "") in
  let unknown_rt () = Brtl_js2_rtng.(root "") in
  ignore
    (Brtl_js2.Router_output.create
       state
       (Brtl_js2.Brr.Document.body Brtl_js2.Brr.G.document)
       Brtl_js2_rtng.
         [
           login_rt () --> Terrat_ui_js_comp_login.run;
           main_rt () --> Terrat_ui_js_comp_main.run;
           installation_install_rt () --> new_installation_install;
           no_installation_rt () --> no_installation;
           (unknown_rt ()
           --> fun _ ->
           Abb_js.Future.return (Brtl_js2.Output.const Brtl_js2.Brr.El.[ txt' "Unknown" ]));
         ]);
  Abb_js.Future.return ()

let () = Brtl_js2.main (Terrat_ui_js_client.create ()) init

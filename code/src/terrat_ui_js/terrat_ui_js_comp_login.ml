let run state =
  let module C = Terrat_api_components.Server_config in
  let open Abb_js.Future.Infix_monad in
  let client = Brtl_js2.State.app_state state in
  Terrat_ui_js_client.server_config client
  >>= function
  | Ok { C.github = Some github } ->
      let module C = Terrat_api_components.Server_config_github in
      Abb_js.Future.return
        (Brtl_js2.Output.navigate
           (Uri.of_string
              (github.C.web_base_url ^ "/login/oauth/authorize?client_id=" ^ github.C.app_client_id)))
  | Ok { C.github = None } -> raise (Failure "nyi")
  | Error _ ->
      Abb_js.Future.return
        (Brtl_js2.Output.const
           Brtl_js2.Brr.El.
             [
               div
                 ~at:
                   Brtl_js2.Brr.At.
                     [
                       class' (Jstr.v "mx-auto");
                       class' (Jstr.v "mt-20");
                       class' (Jstr.v "text-6xl");
                     ]
                 [ txt' "Error" ];
             ])

let run state =
  let open Abb_js.Future.Infix_monad in
  let client = Brtl_js2.State.app_state state in
  Terrat_ui_js_client.server_config client
  >>= function
  | Ok config ->
      let module C = Terrat_api_components.Server_config in
      Abb_js.Future.return
        (Brtl_js2.Output.navigate
           (Uri.of_string
              (config.C.github_web_base_url
              ^ "/login/oauth/authorize?client_id="
              ^ config.C.github_app_client_id)))
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

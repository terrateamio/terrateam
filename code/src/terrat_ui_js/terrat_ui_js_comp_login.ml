module At = Brtl_js2.Brr.At

let github_comp github state =
  let module C = Terrat_api_components.Server_config_github in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       Brtl_js2.Brr.El.
         [
           a
             ~at:
               At.
                 [
                   href
                     (Jstr.v
                        (github.C.web_base_url
                        ^ "/login/oauth/authorize?client_id="
                        ^ github.C.app_client_id));
                 ]
             [
               Tabler_icons_filled.brand_github ();
               div [ txt' "Login with GitHub" ];
               Tabler_icons_outline.arrow_narrow_right ();
             ];
         ])

let gitlab_comp server_config state = raise (Failure "nyi")

let run services state =
  let module C = Terrat_api_components.Server_config in
  let open Abb_js.Future.Infix_monad in
  let client = Brtl_js2.State.app_state state in
  Terrat_ui_js_client.server_config client
  >>= function
  | Ok server_config ->
      Abb_js.Future.return
        (Brtl_js2.Output.const
           Brtl_js2.Brr.El.
             [
               div
                 ~at:At.[ class' (Jstr.v "login") ]
                 [
                   div [ img ~at:At.[ src (Jstr.v "/assets/logo.svg"); class' (Jstr.v "logo") ] () ];
                   div [ txt' "Terrateam" ];
                   div
                     ~at:At.[ class' (Jstr.v "logins") ]
                     (CCList.flat_map
                        (function
                          | Terrat_ui_js_service.Service ((module Service), service) -> (
                              match Service.Comp.Login.is_enabled server_config with
                              | Some config ->
                                  [
                                    Brtl_js2.Router_output.const
                                      (Brtl_js2.State.with_app_state service state)
                                      (div [])
                                      (Service.Comp.Login.run config);
                                  ]
                              | None -> []))
                        services);
                 ];
             ])
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

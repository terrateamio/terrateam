module At = Brtl_js2.Brr.At

let comp state =
  let consumed_path = Brtl_js2.State.consumed_path state in
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let module Repo = Terrat_api_components.Installation_repo in
  let module Page = Terrat_ui_js_comp_page.Make (struct
    type elt = Repo.t
    type state = Terrat_ui_js_state.t

    let class' = "repos"
    let page_param = "page"
    let fetch ?page () = Terrat_ui_js_client.repos ?page ~installation_id:installation.I.id client

    let wrap_page els =
      let refresh_btn =
        Brtl_js2.Kit.Ui.Button.v'
          ~class':(Jstr.v "repos-refresh")
          ~action:(fun () ->
            Brtl_js2.Router.navigate (Brtl_js2.State.router state) (consumed_path ^ "/repos/refresh");
            Abb_js.Future.return ())
          (Brtl_js2.Note.S.const
             ~eq:( == )
             Brtl_js2.Brr.El.
               [
                 txt' "Re-sync";
                 span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "chevron_right" ];
               ])
          ()
      in
      Brtl_js2.Brr.El.
        [
          div
            ~at:At.[ class' (Jstr.v "repos-toolbar") ]
            [
              div [ txt' "Don't see your repo?  Try re-syncing" ];
              div [ Brtl_js2.Kit.Ui.Button.el refresh_btn ];
            ];
          div
            ~at:At.[ class' (Jstr.v "repos-page") ]
            ([
               div ~at:At.[ class' (Jstr.v "page-header") ] [ txt' "Repo" ];
               div ~at:At.[ class' (Jstr.v "page-header") ] [];
             ]
            @ els);
        ]

    let render_elt state repo =
      Brtl_js2.Brr.El.
        [
          div [ txt' repo.Repo.name ];
          div
            [
              a
                ~at:
                  At.
                    [
                      class' (Jstr.v "setup-repo");
                      href (Jstr.v (consumed_path ^ "/repos/new/" ^ repo.Repo.name));
                    ]
                [
                  txt' "Setup Repo";
                  span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "chevron_right" ];
                ];
            ];
        ]

    let equal = Repo.equal
  end) in
  Page.run state

let ph_loading =
  Brtl_js2.Brr.El.
    [
      div
        ~at:At.[ class' (Jstr.v "loading") ]
        [ span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "autorenew" ] ];
    ]

let run = Brtl_js2.Ph.create ph_loading comp

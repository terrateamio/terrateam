module At = Brtl_js2.Brr.At

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  module State = Terrat_ui_js_service_state.Make (Vcs)

  let comp state =
    let consumed_path = Brtl_js2.State.consumed_path state in
    let app_state = Brtl_js2.State.app_state state in
    let vcs = app_state.State.vcs in
    let { State.selected_installation = installation; _ } = app_state.State.v in
    let module Repo = Terrat_api_components.Installation_repo in
    let module Page = Brtl_js2_page.Make (struct
      type fetch_err = Terrat_ui_js_service_vcs.Api.api_err [@@deriving show]
      type elt = Repo.t [@@deriving eq, show]
      type state = State.v State.t
      type query = { page : string list option } [@@deriving eq]

      let class' = "repos"

      let query return =
        let rt = Brtl_js2_rtng.(root consumed_path /? Query.(option (array (string "page")))) in
        Brtl_js2_rtng.(rt --> fun page -> return { page })

      let make_uri { page } uri =
        match page with
        | Some page -> Uri.add_query_param (Uri.remove_query_param uri "page") ("page", page)
        | None -> Uri.remove_query_param uri "page"

      let set_page page _ = { page }

      let fetch { page } =
        Vcs.Api.repos ?page ~installation_id:(Vcs.Installation.id installation) vcs

      let wrap_page query els =
        let refresh_btn =
          Brtl_js2.Kit.Ui.Button.v'
            ~class':(Jstr.v "repos-refresh")
            ~action:(fun () ->
              Brtl_js2.Router.navigate
                (Brtl_js2.State.router state)
                (consumed_path ^ "/repos/refresh");
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

      let render_elt state query repo =
        Brtl_js2.Brr.El.
          [
            div [ txt' repo.Repo.name ];
            div
              [
                (if repo.Repo.setup then
                   a
                     ~at:
                       At.
                         [
                           class' (Jstr.v "setup-repo");
                           href (Jstr.v (consumed_path ^ "/runs?q=repo:" ^ repo.Repo.name));
                         ]
                     [
                       txt' "View Runs";
                       span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "chevron_right" ];
                     ]
                 else
                   a
                     ~at:
                       At.
                         [
                           class' (Jstr.v "setup-repo");
                           href (Jstr.v (consumed_path ^ "/repos/new/" ^ repo.Repo.name));
                         ]
                     [
                       txt' "Setup";
                       span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "chevron_right" ];
                     ]);
              ];
          ]

      let query_comp = None
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
end

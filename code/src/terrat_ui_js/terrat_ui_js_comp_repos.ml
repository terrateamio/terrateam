module At = Brtl_js2.Brr.At

let comp state =
  let consumed_path = Brtl_js2.State.consumed_path state in
  let app_state = Brtl_js2.State.app_state state in
  let client = Terrat_ui_js_state.client app_state in
  let installation = Terrat_ui_js_state.selected_installation app_state in
  let module I = Terrat_api_components.Installation in
  let module Repo = Terrat_api_components.Installation_repo in
  let module Page = Brtl_js2_page.Make (struct
    type fetch_err = Terrat_ui_js_client.err [@@deriving show]
    type elt = Repo.t [@@deriving eq, show]
    type state = Terrat_ui_js_state.t
    type query = { page : string list option } [@@deriving eq]

    let class' = "repos"

    let query =
      let rt = Brtl_js2_rtng.(root consumed_path /? Query.(option (array (string "page")))) in
      Brtl_js2_rtng.(rt --> fun page -> { page })

    let make_uri { page } uri =
      match page with
      | Some page -> Uri.add_query_param (Uri.remove_query_param uri "page") ("page", page)
      | None -> Uri.remove_query_param uri "page"

    let set_page page _ = { page }
    let fetch { page } = Terrat_ui_js_client.repos ?page ~installation_id:installation.I.id client

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
              (if repo.Repo.setup then
                 a
                   ~at:
                     At.
                       [
                         class' (Jstr.v "setup-repo");
                         href (Jstr.v (consumed_path ^ "/audit-trail?q=repo:" ^ repo.Repo.name));
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

module At = Brtl_js2.Brr.At

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  module State = Terrat_ui_js_service_state.Make (Vcs)

  let run state =
    let open Brtl_js2.Brr.El in
    Abb_js.Future.return
      (Brtl_js2.Output.const
         [
           div
             ~at:At.[ class' (Jstr.v "quickstart-page") ]
             [
               div
                 ~at:At.[ class' (Jstr.v "quickstart-header") ]
                 [
                   img
                     ~at:At.[ src (Jstr.v "/assets/logo.svg"); class' (Jstr.v "quickstart-logo") ]
                     ();
                   h1
                     ~at:At.[ class' (Jstr.v "quickstart-welcome") ]
                     [ txt' "Welcome to Terrateam" ];
                   p
                     ~at:At.[ class' (Jstr.v "quickstart-subtitle") ]
                     [ txt' "Choose your path to get started with Terraform automation" ];
                 ];
               div
                 ~at:At.[ class' (Jstr.v "quickstart-options") ]
                 [
                   div
                     ~at:At.[ class' (Jstr.v "quickstart-option") ]
                     [
                       div
                         ~at:At.[ class' (Jstr.v "quickstart-option-content") ]
                         [
                           div
                             ~at:At.[ class' (Jstr.v "quickstart-option-header") ]
                             [
                               Tabler_icons_filled.caret_right
                                 ~at:At.[ class' (Jstr.v "quickstart-icon") ]
                                 ();
                               h3 ~at:At.[ class' (Jstr.v "quickstart-title") ] [ txt' "Try Demo" ];
                             ];
                           p
                             ~at:At.[ class' (Jstr.v "quickstart-description") ]
                             [ txt' "See Terraform plans instantly" ];
                           ul
                             ~at:At.[ class' (Jstr.v "quickstart-features") ]
                             [
                               li
                                 [
                                   Tabler_icons_filled.circle_check
                                     ~at:At.[ class' (Jstr.v "feature-check") ]
                                     ();
                                   div [ txt' "One click setup" ];
                                 ];
                               li
                                 [
                                   Tabler_icons_filled.circle_check
                                     ~at:At.[ class' (Jstr.v "feature-check") ]
                                     ();
                                   div [ txt' "Instant preview" ];
                                 ];
                               li
                                 [
                                   Tabler_icons_filled.circle_check
                                     ~at:At.[ class' (Jstr.v "feature-check") ]
                                     ();
                                   div [ txt' "No config needed" ];
                                 ];
                             ];
                           div
                             ~at:At.[ class' (Jstr.v "quickstart-meta") ]
                             [
                               span
                                 ~at:At.[ class' (Jstr.v "quickstart-note") ]
                                 [ txt' "Safe sandbox" ];
                               span ~at:At.[ class' (Jstr.v "quickstart-time") ] [ txt' "2 min" ];
                             ];
                         ];
                       div
                         ~at:At.[ class' (Jstr.v "quickstart-option-footer") ]
                         [
                           a
                             ~at:
                               At.
                                 [
                                   class' (Jstr.v "btn-primary quickstart-button");
                                   href
                                     (Jstr.v
                                        "https://docs.terrateam.io/getting-started/quickstart-guide#option-1-try-the-demo-recommended");
                                   v (Jstr.v "target") (Jstr.v "_blank");
                                 ]
                             [
                               div [ txt' "Start" ];
                               Tabler_icons_outline.chevron_right
                                 ~at:At.[ class' (Jstr.v "button-icon") ]
                                 ();
                             ];
                         ];
                     ];
                   div
                     ~at:At.[ class' (Jstr.v "quickstart-option") ]
                     [
                       div
                         ~at:At.[ class' (Jstr.v "quickstart-option-content") ]
                         [
                           div
                             ~at:At.[ class' (Jstr.v "quickstart-option-header") ]
                             [
                               Tabler_icons_outline.link
                                 ~at:At.[ class' (Jstr.v "quickstart-icon") ]
                                 ();
                               h3
                                 ~at:At.[ class' (Jstr.v "quickstart-title") ]
                                 [ txt' "Connect Repo" ];
                             ];
                           p
                             ~at:At.[ class' (Jstr.v "quickstart-description") ]
                             [ txt' "Connect your Terraform repo" ];
                           ul
                             ~at:At.[ class' (Jstr.v "quickstart-features") ]
                             [
                               li
                                 [
                                   Tabler_icons_filled.circle_check
                                     ~at:At.[ class' (Jstr.v "feature-check") ]
                                     ();
                                   div [ txt' "Quick install" ];
                                 ];
                               li
                                 [
                                   Tabler_icons_filled.circle_check
                                     ~at:At.[ class' (Jstr.v "feature-check") ]
                                     ();
                                   div [ txt' "Auto setup" ];
                                 ];
                               li
                                 [
                                   Tabler_icons_filled.circle_check
                                     ~at:At.[ class' (Jstr.v "feature-check") ]
                                     ();
                                   div [ txt' "Live in minutes" ];
                                 ];
                             ];
                           div
                             ~at:At.[ class' (Jstr.v "quickstart-meta") ]
                             [
                               span
                                 ~at:At.[ class' (Jstr.v "quickstart-note") ]
                                 [ txt' "Admin access needed" ];
                               span ~at:At.[ class' (Jstr.v "quickstart-time") ] [ txt' "5 min" ];
                             ];
                         ];
                       div
                         ~at:At.[ class' (Jstr.v "quickstart-option-footer") ]
                         [
                           a
                             ~at:
                               At.
                                 [
                                   class' (Jstr.v "btn-secondary quickstart-button-secondary");
                                   href
                                     (Jstr.v
                                        "https://docs.terrateam.io/getting-started/quickstart-guide#option-2-set-up-your-own-repository");
                                   v (Jstr.v "target") (Jstr.v "_blank");
                                 ]
                             [
                               div [ txt' "Connect" ];
                               Tabler_icons_outline.chevron_right
                                 ~at:At.[ class' (Jstr.v "button-icon") ]
                                 ();
                             ];
                         ];
                     ];
                 ];
             ];
         ])
end

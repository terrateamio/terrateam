module At = Brtl_js2.Brr.At

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  module State = Terrat_ui_js_service_state.Make (Vcs)

  let stripe_portal = "https://billing.stripe.com/p/login/00geXngL2cQR0YofYY"

  let billing_info state =
    let app_state = Brtl_js2.State.app_state state in
    let { State.selected_installation; _ } = app_state.State.v in
    let name = Vcs.Installation.name selected_installation in
    let features = Vcs.Installation.tier_features selected_installation in
    let module T = Terrat_ui_js_service_vcs.Tier in
    let { T.num_users_per_month } = features in
    let nupm = CCOption.map_or ~default:"Unlimited users" CCInt.to_string num_users_per_month in
    let trial_ends_at =
      CCOption.map_or ~default:"No expiration" Brtl_js2_datetime.to_iso_string
      @@ Vcs.Installation.trial_ends_at selected_installation
    in
    Brtl_js2.Brr.El.
      [
        div
          ~at:At.[ class' (Jstr.v "billing-info") ]
          [
            div ~at:At.[ class' (Jstr.v "item") ] [ div [ txt' "Plan Name" ]; div [ txt' name ] ];
            div
              ~at:At.[ class' (Jstr.v "item") ]
              [ div [ txt' "Number of users per month" ]; div [ txt' nupm ] ];
            div
              ~at:At.[ class' (Jstr.v "item") ]
              [ div [ txt' "Trial Ends At" ]; div [ txt' trial_ends_at ] ];
            div
              ~at:At.[ class' (Jstr.v "item") ]
              [
                div [ txt' "Billing Portal" ];
                div
                  [
                    a
                      ~at:At.[ class' (Jstr.v "billing-link"); href (Jstr.v stripe_portal) ]
                      [ txt' "Stripe"; Tabler_icons_outline.external_link () ];
                  ];
              ];
          ];
      ]

  let run state = Abb_js.Future.return (Brtl_js2.Output.const @@ billing_info state)
end

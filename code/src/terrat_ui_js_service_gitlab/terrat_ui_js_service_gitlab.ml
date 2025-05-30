module At = Brtl_js2.Brr.At

type t = unit

let create () = Abb_js.Future.return (Ok ())

module User = struct
  type t = unit

  let avatar_url t = raise (Failure "nyi")
end

module Server_config = struct
  type t = unit

  let vcs_web_base_url t = raise (Failure "nyi")
end

module Installation = struct
  type t = unit [@@deriving eq]

  let id t = raise (Failure "nyi")
  let name t = raise (Failure "nyi")
end

module Api = struct
  let whoami t = raise (Failure "nyi")
  let server_config t = raise (Failure "nyi")
  let installations t = raise (Failure "nyi")
  let work_manifests ?tz ?page ?limit ?q ?dir ~installation_id t = raise (Failure "nyi")

  let work_manifest_outputs ?tz ?page ?limit ?q ?lite ~installation_id ~work_manifest_id t =
    raise (Failure "nyi")

  let dirspaces ?tz ?page ?limit ?q ?dir ~installation_id t = raise (Failure "nyi")
  let repos ?page ~installation_id t = raise (Failure "nyi")
  let repos_refresh ~installation_id t = raise (Failure "nyi")
  let task ~id t = raise (Failure "nyi")
end

module Comp = struct
  module Login = struct
    type config = Terrat_api_components.Server_config_gitlab.t

    let is_enabled =
      let module C = Terrat_api_components.Server_config in
      function
      | { C.gitlab; _ } -> gitlab

    let run config state =
      let module C = Terrat_api_components.Server_config_gitlab in
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
                         @@ Uri.to_string
                         @@ Uri.with_query'
                              (Uri.of_string (config.C.web_base_url ^ "/oauth/authorize"))
                              [
                                ("client_id", config.C.app_id);
                                ("redirect_uri", config.C.redirect_url);
                                ("response_type", "code");
                                ("state", "foobar");
                              ]);
                     ]
                 [
                   Tabler_icons_outline.brand_gitlab ();
                   div [ txt' "Login with GitLab (Beta)" ];
                   Tabler_icons_outline.arrow_narrow_right ();
                 ];
             ])
  end

  module No_installations = struct
    let run state = raise (Failure "nyi")
  end

  module Add_installation = struct
    let run state = raise (Failure "nyi")
  end

  module Quickstart = struct
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
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons quickstart-icon") ]
                                   [ txt' "play_circle_filled" ];
                                 h3
                                   ~at:At.[ class' (Jstr.v "quickstart-title") ]
                                   [ txt' "Try Demo" ];
                               ];
                             p
                               ~at:At.[ class' (Jstr.v "quickstart-description") ]
                               [ txt' "See Terraform plans instantly" ];
                             ul
                               ~at:At.[ class' (Jstr.v "quickstart-features") ]
                               [
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "One click setup";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Instant preview";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "No config needed";
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
                                 txt' "Start";
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons button-icon") ]
                                   [ txt' "chevron_right" ];
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
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons quickstart-icon") ]
                                   [ txt' "link" ];
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
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Quick install";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Auto setup";
                                   ];
                                 li
                                   [
                                     span
                                       ~at:At.[ class' (Jstr.v "material-icons feature-check") ]
                                       [ txt' "check_circle" ];
                                     txt' "Live in minutes";
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
                                     class' (Jstr.v "btn-primary quickstart-button");
                                     href
                                       (Jstr.v
                                          "https://docs.terrateam.io/getting-started/quickstart-guide#option-2-set-up-your-own-repository");
                                     v (Jstr.v "target") (Jstr.v "_blank");
                                   ]
                               [
                                 txt' "Connect";
                                 span
                                   ~at:At.[ class' (Jstr.v "material-icons button-icon") ]
                                   [ txt' "chevron_right" ];
                               ];
                           ];
                       ];
                   ];
               ];
           ])
  end
end

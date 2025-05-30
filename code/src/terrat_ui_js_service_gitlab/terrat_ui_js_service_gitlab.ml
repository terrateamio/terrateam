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
                   div [ txt' "Login with GitLab" ];
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
end

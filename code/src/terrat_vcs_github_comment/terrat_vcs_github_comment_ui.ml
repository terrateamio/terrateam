module Ui = struct
  module Api = Terrat_vcs_api_github

  let work_manifest_url config account work_manifest =
    let module Wm = Terrat_work_manifest3 in
    Some
      (Uri.of_string
         (Printf.sprintf
            "%s/i/%d/runs/%s"
            (Uri.to_string (Terrat_config.terrateam_web_base_url @@ Api.Config.config config))
            (Api.Account.id account)
            (Uuidm.to_string work_manifest.Wm.id)))
end

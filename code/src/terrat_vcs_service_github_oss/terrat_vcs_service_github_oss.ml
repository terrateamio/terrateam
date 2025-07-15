let src = Logs.Src.create "vcs_service_github_oss"

module Logs = (val Logs.src_log src : Logs.LOG)

module Provider :
  Terrat_vcs_provider2_github.S
    with type Api.Config.t = Terrat_vcs_service_github_provider.Api.Config.t = struct
  module Api = Terrat_vcs_api_github
  module Unlock_id = Terrat_vcs_service_github_provider.Unlock_id
  module Db = Terrat_vcs_service_github_provider.Db
  module Apply_requirements = Terrat_vcs_service_github_provider.Apply_requirements
  module Tier = Terrat_vcs_service_github_provider.Tier
  module Gate = Terrat_vcs_service_github_provider.Gate
  module Work_manifest = Terrat_vcs_service_github_provider.Work_manifest
  module Repo_config = Terrat_vcs_service_github_provider.Repo_config
  module Access_control = Terrat_vcs_service_github_provider.Access_control
  module Comment = Terrat_vcs_service_github_provider.Comment
  module Commit_check = Terrat_vcs_service_github_provider.Commit_check
  module Ui = Terrat_vcs_service_github_provider.Ui
end

include
  Terrat_vcs_service_github.Make
    (Provider)
    (struct
      type config = Provider.Api.Config.t

      let routes _ _ = []
    end)

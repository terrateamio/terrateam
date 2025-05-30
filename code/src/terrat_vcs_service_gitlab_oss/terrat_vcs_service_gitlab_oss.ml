module Provider : module type of Terrat_vcs_service_gitlab_provider = struct
  module Api = Terrat_vcs_api_gitlab
  module Unlock_id = Terrat_vcs_service_gitlab_provider.Unlock_id
  module Db = Terrat_vcs_service_gitlab_provider.Db
  module Apply_requirements = Terrat_vcs_service_gitlab_provider.Apply_requirements
  module Tier = Terrat_vcs_service_gitlab_provider.Tier
  module Gate = Terrat_vcs_service_gitlab_provider.Gate
  module Work_manifest = Terrat_vcs_service_gitlab_provider.Work_manifest
  module Repo_config = Terrat_vcs_service_gitlab_provider.Repo_config
  module Access_control = Terrat_vcs_service_gitlab_provider.Access_control
  module Comment = Terrat_vcs_service_gitlab_provider.Comment
  module Commit_check = Terrat_vcs_service_gitlab_provider.Commit_check
  module Ui = Terrat_vcs_service_gitlab_provider.Ui
end

include
  Terrat_vcs_service_gitlab.Make
    (Provider)
    (struct
      type config = Provider.Api.Config.t

      let routes _ _ = []
    end)

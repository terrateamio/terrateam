module Provider : Terrat_vcs_provider2_github.S = struct
  module Api = Terrat_vcs_api_github
  module Pull_request = Terrat_vcs_service_github_provider.Pull_request
  module Unlock_id = Terrat_vcs_service_github_provider.Unlock_id
  module Db = Terrat_vcs_service_github_provider.Db
  module Apply_requirements = Terrat_vcs_service_github_provider.Apply_requirements
  module Comment = Terrat_vcs_service_github_provider.Comment
  module Work_manifest = Terrat_vcs_service_github_provider.Work_manifest

  module Repo_config = struct
    let fetch_with_provenance ?system_defaults ?built_config request_id client repo ref_ =
      raise (Failure "nyi")
  end

  module Access_control = struct
    module Ctx = struct
      type t

      let make ~client ~config ~repo ~user () = raise (Failure "nyi")
    end

    let query ctx mtch = raise (Failure "nyi")
    let is_ci_changed ctx diff = raise (Failure "nyi")
    let set_user user ctx = raise (Failure "nyi")
  end

  module Commit_check = struct
    let make ?work_manifest ~config ~description ~title ~status ~repo account =
      raise (Failure "nyi")
  end

  module Ui = struct
    let work_manifest_url config account = raise (Failure "nyi")
  end
end

include Terrat_vcs_service_github.Make (Provider)

module Make (Api : Terrat_vcs_api.S) (Provider : Terrat_vcs_provider2.S) = struct
  module Routes = struct
    let get config storage = raise (Failure "nyi")
  end
end

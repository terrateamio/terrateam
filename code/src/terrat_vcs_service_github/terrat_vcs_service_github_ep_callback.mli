(** GET /api/github/v1/callback

    Where GitHub returns the user after an App installation or an OAuth login. A [state] of
    [stategraph] marks an install started from the Stategraph console: the user is redirected to
    that console's Connect GitHub step with [github_claim=installed], or [github_claim=requested]
    when [setup_action] is [request], and no session is created. Otherwise [code] is required and
    signs the user in. *)
val get :
  Terrat_vcs_service_github_provider.Api.Config.t ->
  Terrat_storage.t ->
  string option ->
  Int64.t option ->
  string option ->
  string option ->
  Brtl_rtng.Handler.t

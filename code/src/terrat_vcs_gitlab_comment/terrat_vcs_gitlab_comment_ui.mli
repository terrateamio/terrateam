module Ui : sig
  val work_manifest_url :
    Terrat_vcs_api_gitlab.Config.t ->
    Terrat_vcs_api_gitlab.Account.t ->
    int option ->
    ('a, Uuidm.t, 'b, 'c, 'd, 'e, 'f, 'g) Terrat_work_manifest3.t ->
    Uri.t option

  val run_url :
    Terrat_vcs_api_gitlab.Config.t -> Terrat_vcs_api_gitlab.Account.t -> Uuidm.t -> Uri.t option
end

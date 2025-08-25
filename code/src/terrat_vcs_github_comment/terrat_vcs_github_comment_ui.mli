module Ui : sig
  val work_manifest_url :
    Terrat_vcs_api_github.Config.t ->
    Terrat_vcs_api_github.Account.t ->
    ('a, Uuidm.t, 'b, 'c, 'd, 'e, 'f, 'g) Terrat_work_manifest3.t ->
    Uri.t option
end

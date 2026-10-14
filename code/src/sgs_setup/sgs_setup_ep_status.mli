(** [GET /api/v1/setup/status]: whether the deployment still needs its in-app setup, and its mode.
    [needs_setup] is [true] until {!Sgs_setup_step.next} answers [`Done] for [requirement], what the
    edition requires before setup may proceed. [api_mode] is the response's [mode] field ([None]
    omits it). *)
val run :
  requirement:Sgs_service_license.requirement ->
  api_mode:(unit -> string option) ->
  Sgs_config.t ->
  Sgs_storage.t ->
  Brtl_rtng.Handler.t

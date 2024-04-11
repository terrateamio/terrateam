type t

val create :
  client:Terrat_ui_js_client.t ->
  user:Terrat_api_components.User.t ->
  installations:Terrat_api_components.Installation.t list Brtl_js2.Note.S.t ->
  selected_installation:Terrat_api_components.Installation.t ->
  server_config:Terrat_api_components.Server_config.t ->
  unit ->
  t

val user : t -> Terrat_api_components.User.t
val client : t -> Terrat_ui_js_client.t
val installations : t -> Terrat_api_components.Installation.t list Brtl_js2.Note.S.t
val selected_installation : t -> Terrat_api_components.Installation.t
val notify : t -> Brtl_js2.Brr.El.t list -> unit
val notifications : t -> Terrat_ui_js_notification.t Brtl_js2.Note.E.t
val server_config : t -> Terrat_api_components.Server_config.t

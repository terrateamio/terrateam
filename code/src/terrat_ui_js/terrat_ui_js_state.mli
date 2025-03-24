type 'a t

val create :
  client:Terrat_ui_js_client.t ->
  user:Terrat_api_components.User.t ->
  installations:Terrat_api_components.Installation.t list Brtl_js2.Note.S.t ->
  selected_installation:Terrat_api_components.Installation.t ->
  server_config:Terrat_api_components.Server_config.t ->
  vcs_config:'a ->
  unit ->
  'a t

val client : 'a t -> Terrat_ui_js_client.t
val installations : 'a t -> Terrat_api_components.Installation.t list Brtl_js2.Note.S.t
val notifications : 'a t -> Terrat_ui_js_notification.t Brtl_js2.Note.E.t
val notify : 'a t -> Brtl_js2.Brr.El.t list -> unit
val selected_installation : 'a t -> Terrat_api_components.Installation.t
val server_config : 'a t -> Terrat_api_components.Server_config.t
val user : 'a t -> Terrat_api_components.User.t
val vcs_config : 'a t -> 'a

type ('user, 'vcs_config) t

val create :
  client:Terrat_ui_js_client.t ->
  user:'user ->
  installations:Terrat_api_components.Installation.t list Brtl_js2.Note.S.t ->
  selected_installation:Terrat_api_components.Installation.t ->
  server_config:Terrat_api_components.Server_config.t ->
  vcs_config:'vcs_config ->
  unit ->
  ('user, 'vcs_config) t

val client : ('user, 'vcs_config) t -> Terrat_ui_js_client.t

val installations :
  ('user, 'vcs_config) t -> Terrat_api_components.Installation.t list Brtl_js2.Note.S.t

val notifications : ('user, 'vcs_config) t -> Terrat_ui_js_notification.t Brtl_js2.Note.E.t
val notify : ('user, 'vcs_config) t -> Brtl_js2.Brr.El.t list -> unit
val selected_installation : ('user, 'vcs_config) t -> Terrat_api_components.Installation.t
val server_config : ('user, 'vcs_config) t -> Terrat_api_components.Server_config.t
val user : ('user, 'vcs_config) t -> 'user
val vcs_config : ('user, 'vcs_config) t -> 'vcs_config

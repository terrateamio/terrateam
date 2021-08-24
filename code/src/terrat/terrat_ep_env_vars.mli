(** User facing secrets management API.  This requires being authenticated with
    the app. *)

(** List the env variables for an installation.  Permissions are checked as
   well.  If the user and installation is not in the installation cache then the
   installations the user has access to is checked against github and cached. *)
val get :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  int64 ->
  int ->
  (string * string) option ->
  Brtl_rtng.Handler.t

(** Add an env variable to an installation.  Permissions are checked as well.
   If the user and installation is not in the installation cache then the
   installations the user has access to is checked against github and cached. *)
val put :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  int64 ->
  Terrat_data.Request.Env_var.t ->
  Brtl_rtng.Handler.t

(** Delete an env variable for an installation.  Permissions are checked as
   well.  If the user and installation is not in the installation cache then the
   installations the user has access to is checked against github and cached. *)
val delete :
  Terrat_config.t ->
  Terrat_storage.t ->
  Githubc_v3.Schema.t ->
  int64 ->
  string ->
  Brtl_rtng.Handler.t

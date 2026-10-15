type delete_err =
  [ `Access_token_not_found_err of Uuidm.t
  | Pgsql_io.err
  ]
[@@deriving show]

type list_err = Pgsql_io.err [@@deriving show]
type store_err = Pgsql_io.err [@@deriving show]

type query_err =
  [ `Expired_err of string
  | `Access_token_not_found_err of Uuidm.t
  | Pgsql_io.err
  ]
[@@deriving show]

type t

val id : t -> Uuidm.t
val user_id : t -> Uuidm.t

(** When the token will expire given as an ISO8691 string *)
val expiration : t -> string option

(** The capabilities granted to this token. Every token row carries a capabilities object (empty
    when none were granted). *)
val capabilities : t -> Sg_caps.t

(** Persist a new access token for [user]. [capabilities] are the capabilities granted to the token
    (the caller is responsible for masking them against the creator's own capabilities). [kind]
    defaults to [`Api], a user-created token; [`Login] marks a browser sign-in session, which the
    token-listing functions hide and which capability changes revoke (see
    {!Sgs_user.revoke_login_sessions}). *)
val store :
  ?kind:[ `Api | `Login ] ->
  ?expiration:Duration.t ->
  name:string ->
  capabilities:Sg_caps.t ->
  'a Sgs_user.t ->
  Pgsql_io.t ->
  (t, [> store_err ]) result Abb.Future.t

(** Query an access token by its id. This returns an error if the token cannot be found, rather than
    an option, this is intended to make it very difficult to accidently use a token that does not
    exist. *)
val query : Uuidm.t -> Pgsql_io.t -> (t, [> query_err ]) result Abb.Future.t

val list_by_user :
  'a Sgs_user.t ->
  Pgsql_io.t ->
  (Sgs_api_components_access_token_summary.t list, [> list_err ]) result Abb.Future.t

val delete :
  token_id:Uuidm.t -> 'a Sgs_user.t -> Pgsql_io.t -> (unit, [> delete_err ]) result Abb.Future.t

val list_all :
  Pgsql_io.t -> (Sgs_api_components_access_token_summary.t list, [> list_err ]) result Abb.Future.t

val delete_any : token_id:Uuidm.t -> Pgsql_io.t -> (unit, [> delete_err ]) result Abb.Future.t

(** Delete every [`Login] row whose expiration has passed, and return how many rows were deleted. An
    expired row no longer authorizes anything ({!query} refuses it), so this is purely garbage
    collection. *)
val gc_expired_login_sessions : Pgsql_io.t -> (int, [> Pgsql_io.err ]) result Abb.Future.t

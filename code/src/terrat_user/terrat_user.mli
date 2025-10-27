(** Represent an authenticated user. At a minimum, this has the internal id for the user, however
    optionally, depending on how this value is created, it can have information around the VCS that
    this user is authenticated against in this instance. *)

type create_system_user_err = Pgsql_io.err [@@deriving show]
type t [@@deriving show, eq]

module Capability : sig
  type t =
    | Access_token_create
    | Access_token_refresh
    | Installation_id of string
    | Kv_store_read
    | Kv_store_write
    | Vcs of string
  [@@deriving show, eq, yojson]

  (** Given a mask and a set of capabilities, return a new set capabilities that has, at most, the
      capabilities in the mask. *)
  val mask : mask:t list -> t list -> t list
end

val make : ?access_token_id:Uuidm.t -> ?capabilities:Capability.t list -> id:Uuidm.t -> unit -> t

val create_system_user :
  ?access_token_id:Uuidm.t ->
  ?capabilities:Capability.t list ->
  Pgsql_io.t ->
  (t, [> create_system_user_err ]) result Abb.Future.t

(** A user authentication may be backed by a token of some kind with an id. This is something that
    is stored in the database. *)
val access_token_id : t -> Uuidm.t option

val id : t -> Uuidm.t
val capabilities : t -> Capability.t list
val has_capability : Capability.t -> t -> bool
val rem_capability : Capability.t -> t -> t

(** A user is authenticated with an access token. An access token is a sequence of bytes. Those
    bytes may just be a Uuid (in the case of cookies) or they may be an encrypted/signed sequence of
    bytes (a JWT in our case), in the case of a Bearer token. An access token may be derived from a
    database entry, in which case it will have an [access_token_id], or it can be a temporary access
    token, in which case it has an expiration, or it may have both. An access token which is a JWT
    can also encode information about the capabilities of the token.

    This module deals with access tokens which a JWT. It allows decoding an existing token or
    encoding a new one. *)
module Token : sig
  type of_token_err' =
    [ `Decode_err
    | `Data_decode_err of string
    | `Expired_token_err of (t[@opaque])
      (** It should be hard to use an expired token, so return it as an error but the decoded token
          is available in case there is a use for it. *)
    ]
  [@@deriving show]

  type of_token_err =
    [ of_token_err'
    | Pgsql_io.err
    ]
  [@@deriving show]

  type to_token_err' =
    [ `Expiration_too_long_err of string
      (** If the expiration is greater than 1 minute, the token is constructed but returned as an
          error to make it harder to use *)
    ]
  [@@deriving show]

  type to_token_err =
    [ to_token_err'
    | Pgsql_io.err
    ]
  [@@deriving show]

  val of_token : Pgsql_io.t -> string -> (t, [> of_token_err ]) result Abb.Future.t

  (** A pure version, if you already have the encryption key. [keys] is a list to support key
      rotation. *)
  val of_token' : now:float -> keys:string list -> string -> (t, [> of_token_err' ]) result

  (** Construct a token given t and how expiration. By default it is 60 seconds *)
  val to_token :
    ?expiration:Duration.t -> Pgsql_io.t -> t -> (string, [> to_token_err ]) result Abb.Future.t

  (** A pure version, if you already have the encryption key *)
  val to_token' :
    ?expiration:Duration.t -> now:float -> key:string -> t -> (string, [> to_token_err' ]) result
end

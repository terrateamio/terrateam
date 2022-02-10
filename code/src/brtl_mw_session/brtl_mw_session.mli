(** Use Cookies to store and retrieve a session identifier.  There are hooks for
   the cookie identifier to be stored and loaded. *)

module Value : sig
  type 'a t
end

(** The type of an [id], which is the session token. *)
type id = string

(** The type of a cookie name. *)
type cookie_name = string

(** The load function which transforms an [id] into the representation of the
   application.  [None] means the [id] is not valid. *)
type 'a load = id -> 'a option Abb.Future.t

(** Store a mapping of an identifier to an application representation.  If the
   [id] is [None] then generate an [id].  The [id] does not have to be the same
   as the [id] passed in, this allows for the hash to be some encoding of the
   application representation. *)
type 'a store = id option -> 'a -> (string, Brtl_rspnc.t) Brtl_ctx.t -> id Abb.Future.t

module Config : sig
  type 'a t = {
    key : 'a Value.t Hmap.key;  (** The key the value is stored in the [Brtl_ctx]. *)
    cookie_name : cookie_name;  (** The name of the cookie. *)
    load : 'a load;  (** The load function. This is called in the [pre_handler]. *)
    store : 'a store;
        (** The store function.  This is called in the
                           [post_handler] if the key in the context has been
                           modified. *)
    expiration : [ `Session | `Max_age of Int64.t ];  (** How long the cookie should last. *)
    domain : string option;  (** The optional domain the cookie applies to. *)
    path : string option;  (** The optional path the cookie applies to. *)
  }
end

val create : 'a Config.t -> Brtl_mw.Mw.t
val set_session_value : 'a Value.t Hmap.key -> 'a -> ('b, 'c) Brtl_ctx.t -> ('b, 'c) Brtl_ctx.t
val get_session_value : 'a Value.t Hmap.key -> ('b, 'c) Brtl_ctx.t -> 'a option
val get_cookie_value : string -> ('a, 'b) Brtl_ctx.t -> string option
val rem_session_value : 'a Value.t Hmap.key -> ('b, 'c) Brtl_ctx.t -> ('b, 'c) Brtl_ctx.t
val create_key : unit -> 'a Value.t Hmap.key

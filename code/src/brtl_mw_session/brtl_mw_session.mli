type id = string

type cookie_name = string

type 'a load = id -> 'a option Abb.Future.t

type 'a store = id option -> 'a -> id Abb.Future.t

module Config : sig
  type 'a t = {
    key : 'a Hmap.key;
    cookie_name : cookie_name;
    load : 'a load;
    store : 'a store;
    expiration : [ `Session | `Max_age of Int64.t ];
    domain : string option;
    path : string option;
  }
end

val create : 'a Config.t -> Brtl_mw.Mw.t

val set_session_value : 'a Hmap.key -> 'a -> ('b, 'c) Brtl_ctx.t -> ('b, 'c) Brtl_ctx.t

val get_session_value : 'a Hmap.key -> ('b, 'c) Brtl_ctx.t -> 'a option

val rem_session_value : 'a Hmap.key -> ('b, 'c) Brtl_ctx.t -> ('b, 'c) Brtl_ctx.t

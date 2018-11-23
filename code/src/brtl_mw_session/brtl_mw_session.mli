module Make(Abb: Abb_intf.S with type Native.t = Unix.file_descr) : sig
  type id = string
  type cookie_name = string

  type 'a load = (id -> 'a option Abb.Future.t)
  type 'a store = (id option -> 'a -> id Abb.Future.t)

  module Config : sig
    type 'a t = { key : 'a Hmap.key
                ; cookie_name : cookie_name
                ; load : 'a load
                ; store : 'a store
                ; expiration : [ `Session | `Max_age of Int64.t ]
                ; domain : string option
                ; path : string option
                }
  end

  val create : 'a Config.t -> Brtl.Make(Abb).Mw.Mw.t

  val set_session_value :
    'a Hmap.key ->
    'a ->
    ('b, 'c) Brtl.Make(Abb).Ctx.t ->
    ('b, 'c) Brtl.Make(Abb).Ctx.t

  val get_session_value : 'a Hmap.key -> ('b, 'c) Brtl.Make(Abb).Ctx.t -> 'a option
end

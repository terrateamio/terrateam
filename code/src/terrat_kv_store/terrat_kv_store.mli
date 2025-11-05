type err = Pgsql_io.err [@@deriving show]

type t' = {
  db : Pgsql_io.t;
  user_caps : Terrat_user.Capability.t list;
}

include
  Kv_store_intf.S
    with type t = t'
     and type key = string * string
     and type path = string * string
     and type data = Yojson.Safe.t
     and type cap = Terrat_user.Capability.t
     and type 'a C.t = ('a, err) result Abb.Future.t

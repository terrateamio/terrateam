type err = Pgsql_io.err [@@deriving show]

include
  Kv_store_intf.S
    with type t = Pgsql_io.t
     and type key = string * string
     and type path = string * string
     and type data = Yojson.Safe.t
     and type 'a C.t = ('a, err) result Abb.Future.t

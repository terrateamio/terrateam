type err = Ttm_client.create_err [@@deriving show]

include
  Kv_store_intf.S
    with type key = string
     and type path = string
     and type data = Yojson.Safe.t
     and type 'a C.t = ('a, err) result Abb.Future.t

val data_record_to_yojson : data Record.t -> Yojson.Safe.t
val create : vcs:string -> installation:string -> Ttm_client.t -> t

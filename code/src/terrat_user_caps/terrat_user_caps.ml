module Cs = Terrat_access_token_caps
module E = Cs.Event

type t =
  | Access_token_create
  | Access_token_refresh
  | Installation_id of string
  | Kv_store_read
  | Kv_store_system_read
  | Kv_store_system_write
  | Kv_store_write
  | Vcs of string
[@@deriving show, eq, ord]

let mask ~mask t =
  let module Set = CCSet.Make (struct
    type nonrec t = t

    let compare = compare
  end) in
  let mask = Set.of_list mask in
  let t = Set.of_list t in
  Set.to_list @@ Set.inter mask t

let to_yojson' = function
  | Access_token_create -> E.Access_token_create "access_token_create"
  | Access_token_refresh -> E.Access_token_refresh "access_token_refresh"
  | Installation_id id -> E.Installation_id { Cs.Installation_id.name = "installation_id"; id }
  | Kv_store_read -> E.Kv_store_read "kv_store_read"
  | Kv_store_system_read -> E.Kv_store_system_read "kv_store_system_read"
  | Kv_store_system_write -> E.Kv_store_system_write "kv_store_system_write"
  | Kv_store_write -> E.Kv_store_write "kv_store_write"
  | Vcs vcs -> E.Vcs { Cs.Vcs.name = "vcs"; vcs }

let to_yojson = CCFun.(to_yojson' %> E.to_yojson)

let of_yojson json =
  let open CCResult.Infix in
  E.of_yojson json
  >>= function
  | E.Access_token_create _ -> Ok Access_token_create
  | E.Access_token_refresh _ -> Ok Access_token_refresh
  | E.Installation_id { Cs.Installation_id.name = _; id } -> Ok (Installation_id id)
  | E.Kv_store_read _ -> Ok Kv_store_read
  | E.Kv_store_system_read _ -> Ok Kv_store_system_read
  | E.Kv_store_system_write _ -> Ok Kv_store_system_write
  | E.Kv_store_write _ -> Ok Kv_store_write
  | E.Vcs { Cs.Vcs.name = _; vcs } -> Ok (Vcs vcs)

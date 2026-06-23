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
  | Mql_admin
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
  | Access_token_create -> E.Access_token_create `Access_token_create
  | Access_token_refresh -> E.Access_token_refresh `Access_token_refresh
  | Installation_id id -> E.Installation_id { Cs.Installation_id.name = `Installation_id; id }
  | Kv_store_read -> E.Kv_store_read `Kv_store_read
  | Kv_store_system_read -> E.Kv_store_system_read `Kv_store_system_read
  | Kv_store_system_write -> E.Kv_store_system_write `Kv_store_system_write
  | Kv_store_write -> E.Kv_store_write `Kv_store_write
  | Vcs vcs -> E.Vcs { Cs.Vcs.name = `Vcs; vcs }
  (* [Mql_admin] has no representation in the generated [Event] type because it
     is intentionally kept out of the public capabilities schema. It is handled
     directly in [to_yojson] below and never reaches here. *)
  | Mql_admin -> assert false

(* [Mql_admin] is serialized as a bare string outside the schema-generated
   [Event] type so it does not appear in the public capabilities API/UI. *)
let to_yojson = function
  | Mql_admin -> `String "mql_admin"
  | t -> E.to_yojson (to_yojson' t)

let of_yojson = function
  | `String "mql_admin" -> Ok Mql_admin
  | json -> (
      let open CCResult.Infix in
      E.of_yojson json
      >>= function
      | E.Access_token_create `Access_token_create -> Ok Access_token_create
      | E.Access_token_refresh `Access_token_refresh -> Ok Access_token_refresh
      | E.Installation_id { Cs.Installation_id.name = `Installation_id; id } ->
          Ok (Installation_id id)
      | E.Kv_store_read `Kv_store_read -> Ok Kv_store_read
      | E.Kv_store_system_read `Kv_store_system_read -> Ok Kv_store_system_read
      | E.Kv_store_system_write `Kv_store_system_write -> Ok Kv_store_system_write
      | E.Kv_store_write `Kv_store_write -> Ok Kv_store_write
      | E.Vcs { Cs.Vcs.name = `Vcs; vcs } -> Ok (Vcs vcs))

let src = Logs.Src.create "kv_store"

module Logs = (val Logs.src_log src : Logs.LOG)

let json_of_caps = CCFun.([%to_yojson: Terrat_user.Capability.t list] %> Yojson.Safe.to_string)

let caps_of_json =
  CCFun.(
    CCOption.wrap Yojson.Safe.from_string
    %> CCOption.flat_map ([%of_yojson: Terrat_user.Capability.t list] %> CCResult.to_opt))

module Sql = struct
  let select_key data =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* committed *)
      Ret.boolean
      //
      (* created_at *)
      Ret.text
      //
      (* data *)
      Ret.ud' (CCOption.wrap Yojson.Safe.from_string)
      //
      (* version *)
      Ret.smallint
      //
      (* size *)
      Ret.integer
      //
      (* read_caps *)
      Ret.(option @@ ud' caps_of_json)
      //
      (* write_caps *)
      Ret.(option @@ ud' caps_of_json)
      /^ CCString.replace
           ~sub:"{{ data }}"
           ~by:data
           {|
            select
              committed,
              to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
              {{ data }},
              version,
              data_size,
              read_caps,
              write_caps
            from kv_store
            where
              namespace = $namespace
              and key = $key
              and idx = $idx
              and (committed or not $committed)
              and (read_caps is null or $user_caps::jsonb @> read_caps)
            order by key, idx
            limit 1
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.smallint "idx"
      /% Var.boolean "committed"
      /% Var.(str_array (text "obj_keys"))
      /% Var.(str_array (jsonpath "jsonpaths"))
      /% Var.(ud (json "user_caps") json_of_caps))

  let upsert_key () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* created_at *)
      Ret.text
      //
      (* version *)
      Ret.smallint
      //
      (* size *)
      Ret.integer
      /^ {|
          insert into kv_store (
            namespace,
            key,
            idx,
            committed,
            data,
            read_caps,
            write_caps
          )
          values (
            $namespace,
            $key,
            $idx,
            $committed,
            $data,
            $read_caps,
            $write_caps
          )
          on conflict (namespace, key, idx) do update set
            version = kv_store.version + 1,
            data = excluded.data,
            created_at = now(),
            committed = excluded.committed,
            read_caps = excluded.read_caps,
            write_caps = excluded.write_caps
          where kv_store.write_caps is null or $user_caps::jsonb @> kv_store.write_caps
          returning
            to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            version,
            data_size
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.smallint "idx"
      /% Var.ud (Var.json "data") Yojson.Safe.to_string
      /% Var.boolean "committed"
      /% Var.(option @@ ud (json "read_caps") json_of_caps)
      /% Var.(option @@ ud (json "write_caps") json_of_caps)
      /% Var.(ud (json "user_caps") json_of_caps))

  let cas_insert () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* created_at *)
      Ret.text
      //
      (* version *)
      Ret.smallint
      //
      (* size *)
      Ret.integer
      /^ {|
          insert into kv_store (
            namespace,
            key,
            idx,
            committed,
            data,
            read_caps,
            write_caps
          )
          values (
            $namespace,
            $key,
            $idx,
            $committed,
            $data,
            $read_caps,
            $write_caps
          )
          on conflict (namespace, key, idx) do nothing
          returning
            to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            version,
            data_size
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.smallint "idx"
      /% Var.ud (Var.json "data") Yojson.Safe.to_string
      /% Var.boolean "committed"
      /% Var.(option (smallint "version"))
      /% Var.(option @@ ud (json "read_caps") json_of_caps)
      /% Var.(option @@ ud (json "write_caps") json_of_caps)
      /% Var.(ud (json "user_caps") json_of_caps))

  let cas_update () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* created_at *)
      Ret.text
      //
      (* version *)
      Ret.smallint
      //
      (* size *)
      Ret.integer
      /^ {|
          update kv_store set
            data = $data,
            version = version + 1,
            committed = $committed,
            created_at = now(),
            read_caps = $read_caps,
            write_caps = $write_caps
          where
            namespace = $namespace
            and key = $key
            and idx = $idx
            and version = $version
            and (write_caps is null or $user_caps::jsonb @> write_caps)
          returning
            to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            version,
            data_size
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.smallint "idx"
      /% Var.ud (Var.json "data") Yojson.Safe.to_string
      /% Var.boolean "committed"
      /% Var.(option (smallint "version"))
      /% Var.(option @@ ud (json "read_caps") json_of_caps)
      /% Var.(option @@ ud (json "write_caps") json_of_caps)
      /% Var.(ud (json "user_caps") json_of_caps))

  let delete () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* version *)
      Ret.smallint
      /^ {|
          delete from kv_store
          where
            namespace = $namespace
            and key = $key
            and ($idx is null or idx = $idx)
            and ($version is null or version = $version)
            and (write_caps is null or $user_caps::jsonb @> write_caps)
          returning
            version
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.(option (smallint "idx"))
      /% Var.(option (smallint "version"))
      /% Var.(ud (json "user_caps") json_of_caps))

  let count () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* count *)
      Ret.integer
      //
      (* max_idx *)
      Ret.integer
      /^ {|
          select
            count(idx),
            max(idx)
          from kv_store
          where
            namespace = $namespace
            and key = $key
            and (committed or not $committed)
            and (read_caps is null or $user_caps::jsonb @> read_caps)
          group by (namespace, key)
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.boolean "committed"
      /% Var.(ud (json "user_caps") json_of_caps))

  let size () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* size *)
      Ret.bigint
      /^ {|
          select
            sum(data_size)
          from kv_store
          where
            namespace = $namespace
            and key = $key
            and (committed or not $committed)
            and ($idx is null or idx = $idx)
            and (read_caps is null or $user_caps::jsonb @> read_caps)
          |}
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.(option (smallint "idx"))
      /% Var.boolean "committed"
      /% Var.(ud (json "user_caps") json_of_caps))

  let iter data cmp =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* key *)
      Ret.text
      //
      (* committed *)
      Ret.boolean
      //
      (* created_at *)
      Ret.text
      //
      (* data *)
      Ret.(ud' (CCOption.wrap Yojson.Safe.from_string))
      //
      (* idx *)
      Ret.smallint
      //
      (* version *)
      Ret.smallint
      //
      (* size *)
      Ret.integer
      //
      (* read_caps *)
      Ret.(option @@ ud' caps_of_json)
      //
      (* write_caps *)
      Ret.(option @@ ud' caps_of_json)
      /^ (CCString.replace ~sub:"{{ data }}" ~by:data
         @@ CCString.replace
              ~sub:"{{ cmp }}"
              ~by:cmp
              {|
            select
              key,
              committed,
              to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
              {{ data }},
              idx,
              version,
              data_size,
              read_caps,
              write_caps
            from kv_store
            where
              namespace = $namespace
              and {{ cmp }}
              and (not $prefix or starts_with(key, $key))
              and (committed or not $committed)
              and (read_caps is null or $user_caps::jsonb @> read_caps)
            order by key, idx
            limit $limit
          |}
         )
      /% Var.text "namespace"
      /% Var.text "key"
      /% Var.(option (smallint "idx"))
      /% Var.boolean "committed"
      /% Var.boolean "prefix"
      /% Var.(ud (integer "limit") CCInt32.of_int)
      /% Var.(str_array (text "obj_keys"))
      /% Var.(str_array (jsonpath "jsonpaths"))
      /% Var.(ud (json "user_caps") json_of_caps))

  let commit () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* namespace *)
      Ret.text
      //
      (* key *)
      Ret.text
      //
      (* idx *)
      Ret.smallint
      /^ {|
          with keys as (
            select namespace, key, idx
            from unnest($namespaces, $keys, $indices) as t(namespace, key, idx)
          )
          update kv_store set committed = true
          from keys
          where
            kv_store.namespace = keys.namespace
            and kv_store.key = keys.key
            and (keys.idx is null or kv_store.idx = keys.idx)
            and not kv_store.committed
            and (kv_store.write_caps is null or $user_caps::jsonb @> kv_store.write_caps)
          returning
            kv_store.namespace,
            kv_store.key,
            kv_store.idx
          |}
      /% Var.(str_array (text "namespaces"))
      /% Var.(str_array (text "keys"))
      /% Var.(array (option (smallint "indices")))
      /% Var.(ud (json "user_caps") json_of_caps))
end

type err = Pgsql_io.err [@@deriving show]

type t' = {
  db : Pgsql_io.t;
  user_caps : Terrat_user.Capability.t list;
}

type t = t'
type key = string * string
type path = string * string
type data = Yojson.Safe.t
type cap = Terrat_user.Capability.t

module C = struct
  type 'a t = ('a, err) result Abb.Future.t
end

module Record = struct
  type 'a t = {
    committed : bool;
    created_at : string;
    data : 'a;
    idx : int;
    key : key;
    size : int;
    version : int;
    read_caps : Terrat_user.Capability.t list option;
    write_caps : Terrat_user.Capability.t list option;
  }

  let committed t = t.committed
  let created_at t = t.created_at
  let data t = t.data
  let idx t = t.idx
  let key t = t.key
  let size t = t.size
  let version t = t.version
  let read_caps t = t.read_caps
  let write_caps t = t.write_caps
end

let eval_select select =
  let obj_keys = CCVector.create () in
  let jsonpaths = CCVector.create () in
  let data =
    match select with
    | None -> "data"
    | Some [] -> "'{}'"
    | Some paths ->
        Printf.sprintf
          "jsonb_build_object(%s)"
          (CCString.concat
             ", "
             (CCList.map
                (fun (k, path) ->
                  CCVector.push obj_keys k;
                  CCVector.push jsonpaths ("lax $." ^ path);
                  let s =
                    Printf.sprintf
                      "($obj_keys)[%d], jsonb_path_query_first(data, ($jsonpaths)[%d])"
                      (CCVector.size obj_keys)
                      (CCVector.size jsonpaths)
                  in
                  s)
                paths))
  in
  (data, CCVector.to_list obj_keys, CCVector.to_list jsonpaths)

let get ?select ?(idx = 0) ?(committed = true) ~key:(namespace, key) t =
  let open Abb.Future.Infix_monad in
  let data, obj_keys, jsonpaths = eval_select select in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.select_key data)
    ~f:(fun committed created_at data version size read_caps write_caps ->
      {
        Record.committed;
        created_at;
        data;
        idx;
        key = (namespace, key);
        size = CCInt32.to_int size;
        version;
        read_caps;
        write_caps;
      })
    namespace
    key
    idx
    committed
    obj_keys
    jsonpaths
    t.user_caps
  >>= function
  | Ok r -> Abb.Future.return (Ok (CCOption.of_list r))
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let set ?read_caps ?write_caps ?(idx = 0) ?(committed = true) ~key:(namespace, key) data t =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.upsert_key ())
    ~f:(fun created_at version size ->
      {
        Record.committed;
        created_at;
        data;
        idx;
        key = (namespace, key);
        size = CCInt32.to_int size;
        version;
        read_caps;
        write_caps;
      })
    namespace
    key
    idx
    data
    committed
    read_caps
    write_caps
    t.user_caps
  >>= function
  | Ok [] -> assert false
  | Ok (r :: _) -> Abb.Future.return (Ok r)
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let cas ?read_caps ?write_caps ?(idx = 0) ?(committed = true) ?version ~key:(namespace, key) data t
    =
  let open Abb.Future.Infix_monad in
  let sql =
    match version with
    | None -> Sql.cas_insert
    | Some _ -> Sql.cas_update
  in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (sql ())
    ~f:(fun created_at version size ->
      {
        Record.committed;
        created_at;
        data;
        idx;
        key = (namespace, key);
        size = CCInt32.to_int size;
        version;
        read_caps;
        write_caps;
      })
    namespace
    key
    idx
    data
    committed
    version
    read_caps
    write_caps
    t.user_caps
  >>= function
  | Ok r -> Abb.Future.return (Ok (CCOption.of_list r))
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let delete ?idx ?version ~key:(namespace, key) t =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.delete ())
    ~f:CCFun.id
    namespace
    key
    idx
    version
    t.user_caps
  >>= function
  | Ok [] -> Abb.Future.return (Ok false)
  | Ok (_ :: _) -> Abb.Future.return (Ok true)
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let count ?(committed = true) ~key:(namespace, key) t =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.count ())
    ~f:(fun count max_idx ->
      { Kv_store_intf.Count.count = CCInt32.to_int count; max_idx = CCInt32.to_int max_idx })
    namespace
    key
    committed
    t.user_caps
  >>= function
  | Ok r -> Abb.Future.return (Ok (CCOption.of_list r))
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let size ?idx ?(committed = true) ~key:(namespace, key) t =
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.size ())
    ~f:CCInt64.to_int
    namespace
    key
    idx
    committed
    t.user_caps
  >>= function
  | Ok r -> Abb.Future.return (Ok (CCOption.of_list r))
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let iter
    ?select
    ?idx
    ?(inclusive = true)
    ?(prefix = false)
    ?(committed = true)
    ?(limit = 30)
    ~key:(namespace, key)
    t =
  let open Abb.Future.Infix_monad in
  let data, obj_keys, jsonpaths = eval_select select in
  let cmp =
    if inclusive then "(key >= $key and ($idx is null or (key = $key and idx >= $idx)))"
    else "(key > $key or (key = $key and ($idx is not null and idx > $idx)))"
  in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.iter data cmp)
    ~f:(fun key committed created_at data idx version size read_caps write_caps ->
      {
        Record.committed;
        created_at;
        data;
        idx;
        key = (namespace, key);
        size = CCInt32.to_int size;
        version;
        read_caps;
        write_caps;
      })
    namespace
    key
    idx
    committed
    prefix
    limit
    obj_keys
    jsonpaths
    t.user_caps
  >>= function
  | Ok r -> Abb.Future.return (Ok r)
  | Error #Pgsql_io.err as err -> Abb.Future.return err

let commit ~keys t =
  let open Abb.Future.Infix_monad in
  let namespaces = CCList.map (fun ((namespace, _key), _idx) -> namespace) keys in
  let indices = CCList.map (fun ((_namespace, _key), idx) -> idx) keys in
  let keys = CCList.map (fun ((_namespace, key), _idx) -> key) keys in
  Pgsql_io.Prepared_stmt.fetch
    t.db
    (Sql.commit ())
    ~f:(fun namespace key idx -> ((namespace, key), idx))
    namespaces
    keys
    indices
    t.user_caps
  >>= function
  | Ok r -> Abb.Future.return (Ok r)
  | Error #Pgsql_io.err as err -> Abb.Future.return err

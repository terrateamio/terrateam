let src = Logs.Src.create "sgs_migrations_ex_685"

module Logs = (val Logs.src_log src : Logs.LOG)

let create_table_hcl_refs_new_state_id_sql =
  Mql_sql.read
    "create table hcl_refs_new (state_id uuid not null, id text not null, ref text not null, \
     attr_path text[] not null default '{}', index_kind text, index_val jsonb, is_bare boolean not \
     null default true, resolvable boolean not null default true, from_depends_on boolean not null \
     default false, ref_state_id uuid, primary key (state_id, id, ref, attr_path, \
     from_depends_on))"

let insert_into_hcl_refs_new_state_id_sql =
  Mql_sql.read
    "insert into hcl_refs_new (state_id, id, ref, attr_path, is_bare, resolvable, from_depends_on, \
     ref_state_id) select orig.state_id, orig.id, orig.ref, '{}'::text[], true, true, false, \
     orig.ref_state_id from hcl_refs orig where not exists (select 1 from hcl_refs_new n where \
     n.state_id = orig.state_id and n.id = orig.id and n.ref = orig.ref) on conflict do nothing"

let drop_table_hcl_refs_cascade_sql = Mql_sql.read "drop table hcl_refs cascade"
let alter_table_hcl_refs_new_rename_sql = Mql_sql.read "alter table hcl_refs_new rename to hcl_refs"

let alter_table_hcl_refs_add_sql =
  Mql_sql.read
    "alter table hcl_refs add foreign key (state_id, id) references hcl (state_id, id) on delete \
     cascade"

let create_index_hcl_refs_state_ref_idx_on_sql =
  Mql_sql.read "create index hcl_refs_state_ref_idx on hcl_refs (state_id, ref)"

let select_chunk_sql =
  Mql_sql.read
    "select state_id, id, coalesce(module_address, '') as module_address, data from hcl where \
     (state_id, id) > ($state_id_cursor, $id_cursor) order by state_id, id limit $limit"

let insert_edge_sql =
  Mql_sql.read
    "insert into hcl_refs_new (state_id, id, ref, attr_path, is_bare, resolvable, from_depends_on) \
     values ($state_id, $id, $ref, $attr_path, $is_bare, $resolvable, $from_depends_on) on \
     conflict do nothing"

(* Single-migration create+populate+swap for hcl_refs.
   1. CREATE TABLE hcl_refs_new with the structured-edges shape (new PK,
      structured columns, no raw_refs).
   2. BACKFILL hcl_refs_new by iterating hcl in chunks and re-running each
      stored AST through [Sgs_tx_log_edges.edges_of_references] — the same
      helper apply_tx uses live, so migrated rows are bit-identical to
      what new code would have written.
   3. PRESERVE any old hcl_refs rows not derivable from hcl.data alone:
      cross-state refs (ref_state_id is not null) and module-input bridge
      rows.  These carry the default (attr_path='{}', is_bare=true) shape.
   4. SWAP — drop the old hcl_refs and rename hcl_refs_new into place; re-install FK and
      indexes.  The legacy [sync_hcl_refs] trigger was dropped by an earlier migration
      ([2026-02-18-drop-sync-hcl-refs-trigger.sql]) and is intentionally NOT recreated:
      [update_state_apply_tx.sql] is now the sole authoritative writer for hcl_refs.
   The whole thing runs inside the migration framework's single
   transaction; end state is hcl_refs with the desired final shape and
   no separate side table. *)
let run db =
  let open Abbs_fc.Infix_result_monad in
  let module Ts = Pgsql_io.Typed_sql in
  let module Ps = Pgsql_io.Prepared_stmt in
  let exec stmt = Ps.execute db Ts.(sql /^ stmt) in
  let chunk_limit = 1000 in
  let select_chunk =
    Ts.(
      sql
      // Ret.uuid
      // Ret.text
      // Ret.text
      // Ret.jsonb
      /^ select_chunk_sql
      /% Var.uuid "state_id_cursor"
      /% Var.text "id_cursor"
      /% Var.integer "limit")
  in
  let insert_edge =
    Ts.(
      sql
      /^ insert_edge_sql
      /% Var.uuid "state_id"
      /% Var.text "id"
      /% Var.text "ref"
      /% Var.(str_array (text "attr_path"))
      /% Var.boolean "is_bare"
      /% Var.boolean "resolvable"
      /% Var.boolean "from_depends_on")
  in
  let edge_fields (e : Sgs_tx_log_data.Edge.t) =
    ( e.Sgs_tx_log_data.Edge.to_addr,
      e.Sgs_tx_log_data.Edge.attr_path,
      e.Sgs_tx_log_data.Edge.is_bare,
      e.Sgs_tx_log_data.Edge.resolvable,
      e.Sgs_tx_log_data.Edge.from_depends_on )
  in
  (* Mirror of [Sgs_tx_log.process_hcl_value]'s edge derivation:
     - [moved] blocks contribute no edges (their [from]/[to] are remap directives, not graph deps).
     - Refs inside check blocks (precondition / postcondition / validation / assert) are subtracted
       from the typed-edge set and re-emitted as bare edges so the substitution decision skips them.
     Without these, migrated rows diverge from what new code would have written and the cone walk
     can mis-substitute check-block boundaries. *)
  let qualify module_address s =
    CCOption.map_or ~default:s (fun mp -> mp ^ "." ^ s) module_address
  in
  let derive_edges state_id id module_address_str data_json =
    let module_address =
      if CCString.equal module_address_str "" then None else Some module_address_str
    in
    match Hcl_parser_value_json.Safe.to_ast data_json with
    | Error _ -> []
    | Ok asts ->
        CCList.flat_map
          (fun v ->
            let is_moved =
              match v with
              | Hcl_parser_value.Block { type_ = "moved"; _ } -> true
              | Hcl_parser_value.Block _ | Hcl_parser_value.Attribute _ -> false
            in
            if is_moved then []
            else
              let raw_refs = Sg_tf_references.references v in
              let check_block_refs = Sg_tf_references.check_block_references v in
              let typed_refs = Sg_tf_references.Reference_set.diff raw_refs check_block_refs in
              let dep_refs = Sg_tf_references.depends_on_references v in
              let mk b refs =
                (* A backfill reads STORED references. A selector is part of the expression that
                   made them, and that expression is no longer available. Thus each row that this
                   migration writes has no selector. The state gets the selectors when the server
                   encodes it again, which the state schema version already makes necessary. *)
                Sgs_tx_log_edges.edges_of_references
                  ~module_address
                  ~from_depends_on:b
                  ~selectors:[]
                  refs
                |> CCList.map edge_fields
                |> CCList.map (fun (to_addr, ap, ib, rv, fdo) ->
                    (state_id, id, to_addr, ap, ib, rv, fdo))
              in
              let check_block_edges =
                Sg_tf_references.Reference_set.fold
                  (fun ref_ acc ->
                    CCOption.map_or
                      ~default:acc
                      (fun base_addr ->
                        (state_id, id, qualify module_address base_addr, [], true, true, false)
                        :: acc)
                      (Sg_tf_references.address_of_reference ref_))
                  check_block_refs
                  []
              in
              mk false typed_refs @ check_block_edges @ mk true dep_refs)
          asts
  in
  let insert_one (state_id, id, to_addr, attr_path, is_bare, resolvable, from_depends_on) =
    Ps.execute db insert_edge state_id id to_addr attr_path is_bare resolvable from_depends_on
  in
  Logs.info (fun m -> m "HCL_REFS_STRUCTURED_EDGES : creating staging table");
  exec create_table_hcl_refs_new_state_id_sql
  >>= fun () ->
  Logs.info (fun m -> m "HCL_REFS_STRUCTURED_EDGES : backfilling from hcl.data");
  let rec loop ~state_id_cursor ~id_cursor ~total =
    Ps.fetch
      db
      select_chunk
      ~f:(fun state_id id module_addr data -> (state_id, id, module_addr, data))
      state_id_cursor
      id_cursor
      (Int32.of_int chunk_limit)
    >>= fun rows ->
    match rows with
    | [] ->
        Logs.info (fun m -> m "HCL_REFS_STRUCTURED_EDGES : backfilled %d hcl rows" total);
        Abbs_fc.return_ok ()
    | _ ->
        let edges =
          CCList.flat_map
            (fun (state_id, id, module_addr, data) -> derive_edges state_id id module_addr data)
            rows
        in
        Abbs_fc.List_result.iter ~f:insert_one edges
        >>= fun () ->
        let last_state_id, last_id, _, _ =
          CCList.last_opt rows |> CCOption.get_exn_or "non-empty chunk"
        in
        loop ~state_id_cursor:last_state_id ~id_cursor:last_id ~total:(total + CCList.length rows)
  in
  loop ~state_id_cursor:Uuidm.nil ~id_cursor:"" ~total:0
  >>= fun () ->
  Logs.info (fun m ->
      m "HCL_REFS_STRUCTURED_EDGES : preserving cross-state and module-input bridge rows");
  exec insert_into_hcl_refs_new_state_id_sql
  >>= fun () ->
  Logs.info (fun m -> m "HCL_REFS_STRUCTURED_EDGES : swapping tables");
  exec drop_table_hcl_refs_cascade_sql
  >>= fun () ->
  exec alter_table_hcl_refs_new_rename_sql
  >>= fun () ->
  exec alter_table_hcl_refs_add_sql
  >>= fun () ->
  exec create_index_hcl_refs_state_ref_idx_on_sql
  >>| fun () ->
  Logs.info (fun m -> m "HCL_REFS_STRUCTURED_EDGES : complete");
  `Sync

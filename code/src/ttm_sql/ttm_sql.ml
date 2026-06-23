let src = Logs.Src.create "sql"

module Logs = (val Logs.src_log src : Logs.LOG)

let default_api_base = "https://app.terrateam.io"

module Output = struct
  type format =
    | Json
    | Table
    | Simple

  let format_of_string = function
    | "json" -> Ok Json
    | "table" -> Ok Table
    | "simple" -> Ok Simple
    | s -> Error (`Msg (Printf.sprintf "Unknown format: %s (expected json, table, or simple)" s))

  let pp_format fmt = function
    | Json -> Format.pp_print_string fmt "json"
    | Table -> Format.pp_print_string fmt "table"
    | Simple -> Format.pp_print_string fmt "simple"

  let format_conv = Cmdliner.Arg.conv (format_of_string, pp_format)

  let format_arg =
    let doc =
      "Output format: table (default, human-readable columns), json, or simple (one value per \
       line, no headers)."
    in
    Cmdliner.Arg.(value & opt format_conv Table & info [ "format" ] ~doc)

  type t = {
    json : Yojson.Safe.t;
    headers : string list;
    rows : string list list;
  }

  let make ~json ~headers ~rows = { json; headers; rows }
  let print_json yojson = print_endline (Yojson.Safe.pretty_to_string yojson)

  let print_table ~headers rows =
    let n_headers = CCList.length headers in
    let rows =
      CCList.filter_map
        (fun row ->
          let n = CCList.length row in
          if n = n_headers then Some row
          else if n < n_headers then Some (row @ CCList.init (n_headers - n) (fun _ -> ""))
          else Some (CCList.take n_headers row))
        rows
    in
    match rows with
    | [] -> ()
    | _ ->
        let col_widths =
          let header_widths = CCList.map CCString.length headers in
          CCList.fold_left
            (fun widths row -> CCList.map2 (fun w cell -> max w (CCString.length cell)) widths row)
            header_widths
            rows
        in
        let print_row row =
          CCList.iter2 (fun width cell -> Printf.printf "%-*s  " width cell) col_widths row;
          print_newline ()
        in
        print_row headers;
        CCList.iter (fun width -> Printf.printf "%s  " (CCString.make width '-')) col_widths;
        print_newline ();
        CCList.iter print_row rows

  let print_simple rows = CCList.iter (fun row -> print_endline (CCString.concat "\t" row)) rows

  let json_value_to_string = function
    | `String s -> s
    | `Int i -> CCInt.to_string i
    | `Float f -> Printf.sprintf "%g" f
    | `Bool b -> if b then "true" else "false"
    | `Null -> ""
    | other -> Yojson.Safe.to_string other

  let json_objects_to_rows json_list =
    let headers =
      match json_list with
      | `Assoc pairs :: _ -> CCList.map fst pairs
      | _ -> []
    in
    let rows =
      CCList.filter_map
        (function
          | `Assoc pairs ->
              Some
                (CCList.map
                   (fun h ->
                     CCList.Assoc.get ~eq:CCString.equal h pairs
                     |> CCOption.map_or ~default:"" json_value_to_string)
                   headers)
          | _ -> None)
        json_list
    in
    (headers, rows)

  let output format t =
    match format with
    | Json -> print_json t.json
    | Table -> print_table ~headers:t.headers t.rows
    | Simple -> print_simple t.rows
end

module Args = struct
  module C = Cmdliner

  let api_base =
    let doc = "API base for Terrateam calls" in
    let env = C.Cmd.Env.info "TTM_API_BASE" in
    C.Arg.(required & opt (some string) (Some default_api_base) & info [ "api-base" ] ~doc ~env)

  let installation_id =
    let doc = "Installation ID to scope the query to" in
    C.Arg.(required & opt (some string) None & info [ "i"; "installation-id" ] ~doc)

  let vcs =
    let doc = "VCS provider hosting the installation: github (default) or gitlab" in
    C.Arg.(
      value & opt (enum [ ("github", `Github); ("gitlab", `Gitlab) ]) `Github & info [ "vcs" ] ~doc)

  let tz =
    let doc = "Timezone to apply to the query session (e.g. 'UTC', 'America/New_York')" in
    C.Arg.(value & opt (some string) None & info [ "tz" ] ~doc)

  let page =
    let doc =
      "Pagination cursor returned by a previous query (passes the value through unchanged)"
    in
    C.Arg.(value & opt (some string) None & info [ "page" ] ~doc)

  let query =
    let doc = "SQL query, e.g. \"SELECT * FROM work_manifests WHERE state = 'completed'\"" in
    C.Arg.(required & pos ~rev:true 0 (some string) None & info [] ~doc ~docv:"QUERY")
end

let exec f =
  match Abb.Scheduler.run_with_state f with
  | `Det n -> exit n
  | `Aborted ->
      Logs.err (fun m -> m "Aborted");
      exit 1
  | `Exn (exn, bt_opt) ->
      Logs.err (fun m -> m "%s" (Printexc.to_string exn));
      CCOption.iter
        (fun bt -> Logs.err (fun m -> m "%s" (Printexc.raw_backtrace_to_string bt)))
        bt_opt;
      exit 1

(* Find the URI carried by the link header for a given [rel]. The header is a
   comma-separated list of [<uri>; rel="rel"] entries — match by the trailing
   rel attribute. *)
let extract_link headers rel =
  match CCList.Assoc.get ~eq:CCString.equal "link" headers with
  | None -> None
  | Some link ->
      link
      |> CCString.split ~by:","
      |> CCList.find_map (fun entry ->
          let entry = CCString.trim entry in
          let rel_tag = Printf.sprintf "rel=\"%s\"" rel in
          if CCString.mem ~sub:rel_tag entry then
            match (CCString.index_opt entry '<', CCString.index_opt entry '>') with
            | Some lo, Some hi when hi > lo + 1 -> Some (CCString.sub entry (lo + 1) (hi - lo - 1))
            | _ -> None
          else None)

(* The endpoint returns the [page] cursor inside the [link] header URI's query
   string. Pull just that value back out so the caller can pass it to
   [--page]. *)
let cursor_of_link uri =
  match Uri.get_query_param (Uri.of_string uri) "page" with
  | Some cursor -> cursor
  | None -> uri

let report_pagination_hints headers =
  let report rel =
    match extract_link headers rel with
    | None -> ()
    | Some uri ->
        let cursor = cursor_of_link uri in
        Printf.eprintf "%s page: --page '%s'\n" rel cursor
  in
  report "next";
  report "prev";
  match CCList.Assoc.get ~eq:CCString.equal "mql-pagination-error" headers with
  | Some err -> Printf.eprintf "pagination error: %s\n" err
  | None -> ()

let report_bad_request id data =
  let detail = CCOption.get_or ~default:"" data in
  match id with
  | "UNKNOWN_COLUMN_ERR" ->
      Printf.eprintf "Error: Unknown column '%s'.\n" detail;
      Printf.eprintf "\nTo fix: run 'ttm sql schema -i <installation>' to see available columns.\n"
  | "TABLE_ACCESS_ERR" ->
      Printf.eprintf "Error: Unknown or disallowed table '%s'.\n" detail;
      Printf.eprintf "\nTo fix: run 'ttm sql schema -i <installation>' to see available tables.\n"
  | "AMBIGUOUS_COLUMN_ERR" ->
      Printf.eprintf "Error: Ambiguous column '%s'. Qualify with table name.\n" detail
  | _ ->
      Printf.eprintf "Error: %s" id;
      if CCString.length detail > 0 then Printf.eprintf " (%s)" detail;
      Printf.eprintf "\n"

module Query = struct
  let has_limit query =
    match Mql.Ast.of_string query with
    | Ok ast -> CCOption.is_some (Mql.Ast.limit ast)
    | Error _ -> false

  let make_request vcs ~installation_id ~q ~tz ~page =
    match vcs with
    | `Github ->
        let module A = Terrat_api_installations.Mql in
        A.make (A.Parameters.make ~installation_id ~q ~tz ~page ())
    | `Gitlab ->
        let module A = Terrat_api_installations.Gitlab_mql in
        A.make (A.Parameters.make ~installation_id ~q ~tz ~page ())

  let rows_to_yojson rows = `List rows

  let run api_base vcs installation_id tz page format query () =
    let _ = has_limit query in
    let f () =
      let open Abb.Future.Infix_monad in
      Ttm_client.create ~base_url:(Uri.of_string api_base) ()
      >>= function
      | Error (#Ttm_client.create_err as err) ->
          Printf.eprintf
            "Error: could not connect to Terrateam API at %s: %s\n"
            api_base
            (Ttm_client.show_create_err err);
          Abb.Future.return 1
      | Ok client -> (
          Ttm_client.call client (make_request vcs ~installation_id ~q:query ~tz ~page)
          >>= function
          | Error (#Ttm_client.create_err as err) ->
              Printf.eprintf "Error: API call failed: %s\n" (Ttm_client.show_create_err err);
              Abb.Future.return 1
          | Ok resp -> (
              let headers = Openapi.Response.headers resp in
              match Openapi.Response.value resp with
              | `OK rows ->
                  let json = rows_to_yojson rows in
                  let headers_tbl, rows_tbl = Output.json_objects_to_rows rows in
                  Output.output format (Output.make ~json ~headers:headers_tbl ~rows:rows_tbl);
                  report_pagination_hints headers;
                  Abb.Future.return 0
              | `Bad_request { Terrat_api_components.Bad_request_err.id; data } ->
                  report_bad_request id data;
                  Abb.Future.return 2
              | `Forbidden ->
                  Printf.eprintf "Unauthorized\n";
                  Abb.Future.return 1))
    in
    exec f

  let cmd logs =
    let module C = Cmdliner in
    let doc =
      "Run a SQL query against your Terrateam installation. Use 'ttm sql schema' to discover \
       available tables and columns."
    in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v
      (C.Cmd.info "query" ~doc ~exits)
      C.Term.(
        const run
        $ Args.api_base
        $ Args.vcs
        $ Args.installation_id
        $ Args.tz
        $ Args.page
        $ Output.format_arg
        $ Args.query
        $ logs)
end

module Schema = struct
  module R = Terrat_api_components_mql_schema_response
  module T = Terrat_api_components_mql_schema_table
  module Col = Terrat_api_components_mql_schema_column

  let make_request vcs ~installation_id =
    match vcs with
    | `Github ->
        let module A = Terrat_api_installations.Mql_schema in
        A.make (A.Parameters.make ~installation_id)
    | `Gitlab ->
        let module A = Terrat_api_installations.Gitlab_mql_schema in
        A.make (A.Parameters.make ~installation_id)

  let schema_to_rows schema =
    let tables = R.Tables.additional schema.R.tables in
    let headers = [ "table"; "column"; "type" ] in
    let rows =
      Sln_map.String.fold
        (fun table_name table acc ->
          let columns = T.Columns.additional table.T.columns in
          Sln_map.String.fold
            (fun col_name col inner_acc -> [ table_name; col_name; col.Col.type_ ] :: inner_acc)
            columns
            acc)
        tables
        []
    in
    let rows = CCList.sort (CCList.compare CCString.compare) rows in
    (headers, rows)

  let run api_base vcs installation_id format () =
    let f () =
      let open Abb.Future.Infix_monad in
      Ttm_client.create ~base_url:(Uri.of_string api_base) ()
      >>= function
      | Error #Ttm_client.create_err ->
          Printf.eprintf "Error: could not connect to Terrateam API at %s\n" api_base;
          Abb.Future.return 1
      | Ok client -> (
          Ttm_client.call client (make_request vcs ~installation_id)
          >>= function
          | Error #Ttm_client.create_err ->
              Printf.eprintf "Error: API call failed\n";
              Abb.Future.return 1
          | Ok resp -> (
              match Openapi.Response.value resp with
              | `OK schema ->
                  let json = Yojson.Safe.sort (R.to_yojson schema) in
                  let headers, rows = schema_to_rows schema in
                  Output.output format (Output.make ~json ~headers ~rows);
                  Abb.Future.return 0
              | `Forbidden ->
                  Printf.eprintf "Unauthorized\n";
                  Abb.Future.return 1))
    in
    exec f

  let cmd logs =
    let module C = Cmdliner in
    let doc =
      "Fetch the SQL schema showing all available tables and columns. Use --format table for a \
       flat list of table/column/type rows."
    in
    let exits = C.Cmd.Exit.defaults in
    C.Cmd.v
      (C.Cmd.info "schema" ~doc ~exits)
      C.Term.(
        const run $ Args.api_base $ Args.vcs $ Args.installation_id $ Output.format_arg $ logs)
end

let cmd logs =
  let module C = Cmdliner in
  let doc =
    "Query your Terrateam installation using SQL. Start with 'ttm sql schema -i <installation>' to \
     discover available tables."
  in
  let info = C.Cmd.info ~doc "sql" in
  C.Cmd.group info [ Query.cmd logs; Schema.cmd logs ]

module Work_manifests = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map
           (fun s ->
             s
             |> CCString.split_on_char '\n'
             |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
             |> CCString.concat "\n")
           (Terrat_files_sql.read fname))

    let dirspaces =
      let module T = struct
        type t = Terrat_api_components.Work_manifest_dirspace.t list [@@deriving yojson]
      end in
      CCFun.(
        CCOption.wrap Yojson.Safe.from_string
        %> CCOption.map T.of_yojson
        %> CCOption.flat_map CCResult.to_opt)

    let select_work_manifests () =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.uuid
        // (* base_hash *) Ret.text
        // (* completed_at *) Ret.(option text)
        // (* created_at *) Ret.text
        // (* hash *) Ret.text
        // (* run_type *) Ret.ud' Terrat_work_manifest.Run_type.of_string
        // (* state *) Ret.ud' Terrat_work_manifest.State.of_string
        // (* tag_query *) Ret.ud' CCFun.(Terrat_tag_query.of_string %> CCOption.of_result)
        // (* repository *) Ret.bigint
        // (* pull_number *) Ret.(option bigint)
        // (* base_branch *) Ret.text
        // (* owner *) Ret.text
        // (* repo *) Ret.text
        // (* run_kind *) Ret.text
        // (* dirspaces *) Ret.(option (ud' dirspaces))
        // (* pull_request_title *) Ret.(option text)
        // (* branch *) Ret.(option text)
        // (* username *) Ret.(option text)
        // (* run_id *) Ret.(option text)
        /^ read "select_github_work_manifests_page.sql"
        /% Var.uuid "user"
        /% Var.bigint "installation_id"
        /% Var.(option (bigint "pull_number"))
        /% Var.option (Var.text "prev_created_at")
        /% Var.option (Var.uuid "prev_id"))
  end

  let columns =
    Pgsql_pagination.Search.Col.
      [ create ~vname:"prev_created_at" ~cname:"created_at"; create ~vname:"prev_id" ~cname:"id" ]

  module Page = struct
    type cursor = string * Uuidm.t

    type query = {
      user : Uuidm.t;
      pull_request : int option;
      storage : Terrat_storage.t;
      installation_id : int;
      dir : [ `Asc | `Desc ];
      limit : int;
    }

    type t = Terrat_api_components.Installation_work_manifest.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
      let search = Pgsql_pagination.Search.(create ~page_size:query.limit ~dir:query.dir columns) in
      let created_at, id =
        match cursor with
        | Some (created_at, id) -> (Some created_at, Some id)
        | None -> (None, None)
      in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          f
            search
            db
            (Sql.select_work_manifests ())
            ~f:(fun
                id
                base_ref
                completed_at
                created_at
                ref_
                run_type
                state
                tag_query
                repository
                pull_number
                base_branch
                owner
                repo
                run_kind
                dirspaces
                pull_request_title
                branch
                user
                run_id
              ->
              let module D = Terrat_api_components.Installation_work_manifest_drift in
              let module Pr = Terrat_api_components.Installation_work_manifest_pull_request in
              let module Wm = Terrat_api_components.Installation_work_manifest in
              match (run_kind, pull_number, branch) with
              | "drift", _, _ ->
                  Wm.Installation_work_manifest_drift
                    D.
                      {
                        base_branch;
                        base_ref;
                        completed_at;
                        created_at;
                        dirspaces = CCOption.get_or ~default:[] dirspaces;
                        id = Uuidm.to_string id;
                        owner;
                        ref_;
                        repo;
                        repository = CCInt64.to_int repository;
                        run_type = Terrat_work_manifest.Run_type.to_string run_type;
                        state = Terrat_work_manifest.State.to_string state;
                        run_id;
                      }
              | "", Some pull_number, Some branch ->
                  Wm.Installation_work_manifest_pull_request
                    Pr.
                      {
                        base_branch;
                        base_ref;
                        branch;
                        completed_at;
                        created_at;
                        dirspaces = CCOption.get_or ~default:[] dirspaces;
                        id = Uuidm.to_string id;
                        owner;
                        pull_number = CCInt64.to_int pull_number;
                        pull_request_title;
                        ref_;
                        repo;
                        repository = CCInt64.to_int repository;
                        run_type = Terrat_work_manifest.Run_type.to_string run_type;
                        state = Terrat_work_manifest.State.to_string state;
                        tag_query = Terrat_tag_query.to_string tag_query;
                        user;
                        run_id;
                      }
              | _, _, _ ->
                  Logs.info (fun m -> m "Unknown run_kind %a" Uuidm.pp id);
                  raise (Failure ("Failed " ^ Uuidm.to_string id)))
            query.user
            (CCInt64.of_int query.installation_id)
            (CCOption.map CCInt64.of_int query.pull_request)
            created_at
            id)

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_work_manifests.Responses.OK.(
        { work_manifests = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el =
      let module Wm = Terrat_api_components.Installation_work_manifest in
      let module D = Terrat_api_components.Installation_work_manifest_drift in
      let module Pr = Terrat_api_components.Installation_work_manifest_pull_request in
      function
      | Wm.Installation_work_manifest_drift D.{ id; created_at; _ }
      | Wm.Installation_work_manifest_pull_request Pr.{ id; created_at; _ } ->
          Some [ created_at; id ]

    let cursor_of_first t =
      match Pgsql_pagination.results t with
      | [] -> None
      | wm :: _ -> cursor_of_el wm

    let cursor_of_last t =
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | wm :: _ -> cursor_of_el wm

    let has_another_page t = Pgsql_pagination.has_next_page t

    let log_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err)
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err)
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id pr_opt dir page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.
            {
              user =
                CCOption.get_exn_or
                  "uuid of user"
                  (Uuidm.of_string user.Terrat_api_components.User.id);
              pull_request = pr_opt;
              storage;
              installation_id;
              dir = CCOption.get_or ~default:`Desc dir;
              limit;
            }
        in
        Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx))
end

module Pull_requests = struct
  module Sql = struct
    let read fname =
      CCOption.get_exn_or
        fname
        (CCOption.map
           (fun s ->
             s
             |> CCString.split_on_char '\n'
             |> CCList.filter CCFun.(CCString.prefix ~pre:"--" %> not)
             |> CCString.concat "\n")
           (Terrat_files_sql.read fname))

    let select_pull_requests () =
      Pgsql_io.Typed_sql.(
        sql
        // (* base_branch *) Ret.text
        // (* base_sha *) Ret.text
        // (* branch *) Ret.text
        // (* latest_work_manifest_run_at *) Ret.(option text)
        // (* merged_at *) Ret.(option text)
        // (* merged_sha *) Ret.(option text)
        // (*name *) Ret.text
        // (* owner *) Ret.text
        // (* pull_number *) Ret.bigint
        // (* repository *) Ret.bigint
        // (* sha *) Ret.text
        // (* state *) Ret.text
        // (* title *) Ret.(option text)
        // (* username *) Ret.(option text)
        /^ read "select_github_pull_requests_page.sql"
        /% Var.uuid "user"
        /% Var.bigint "installation_id"
        /% Var.(option (bigint "pull_number"))
        /% Var.option (Var.bigint "prev_pull_number"))
  end

  let columns =
    Pgsql_pagination.Search.Col.[ create ~vname:"prev_pull_number" ~cname:"pull_number" ]

  module Page = struct
    type cursor = int64

    type query = {
      user : Uuidm.t;
      pull_request : int option;
      storage : Terrat_storage.t;
      installation_id : int;
      limit : int;
    }

    type t = Terrat_api_components.Installation_pull_request.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
      let search = Pgsql_pagination.Search.(create ~page_size:query.limit ~dir:`Desc columns) in
      let pull_number = cursor in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          f
            search
            db
            (Sql.select_pull_requests ())
            ~f:(fun
                base_branch
                base_sha
                branch
                latest_work_manifest_run_at
                merged_at
                merged_sha
                name
                owner
                pull_number
                repository
                sha
                state
                title
                user
              ->
              let module Pr = Terrat_api_components.Installation_pull_request in
              Pr.
                {
                  base_branch;
                  base_sha;
                  branch;
                  latest_work_manifest_run_at;
                  merged_at;
                  merged_sha;
                  name;
                  owner;
                  pull_number = CCInt64.to_int pull_number;
                  repository = CCInt64.to_int repository;
                  sha;
                  state;
                  title;
                  user;
                })
            query.user
            (CCInt64.of_int query.installation_id)
            (CCOption.map CCInt64.of_int query.pull_request)
            pull_number)

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_pull_requests.Responses.OK.(
        { pull_requests = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_el =
      let module Pr = Terrat_api_components.Installation_pull_request in
      function
      | Pr.{ pull_number; _ } -> Some [ CCInt.to_string pull_number ]

    let cursor_of_first t =
      match Pgsql_pagination.results t with
      | [] -> None
      | pr :: _ -> cursor_of_el pr

    let cursor_of_last t =
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | pr :: _ -> cursor_of_el pr

    let has_another_page t = Pgsql_pagination.has_next_page t

    let log_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err)
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err)
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id pr_opt page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.
            {
              user =
                CCOption.get_exn_or
                  "uuid of user"
                  (Uuidm.of_string user.Terrat_api_components.User.id);
              pull_request = pr_opt;
              storage;
              installation_id;
              limit;
            }
        in
        Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx))
end

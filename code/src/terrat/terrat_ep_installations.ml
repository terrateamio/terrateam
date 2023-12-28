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
          let open Abbs_future_combinators.Infix_result_monad in
          Pgsql_io.Prepared_stmt.execute db (Sql.set_timeout ())
          >>= fun () ->
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

    let rspnc_of_err ~token = function
      | `Statement_timeout ->
          let module Bad_request =
            Terrat_api_installations.List_work_manifests.Responses.Bad_request
          in
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : STATEMENT_TIMEOUT" token);
          let body =
            Bad_request.(
              { id = "STATEMENT_TIMEOUT"; data = None } |> to_yojson |> Yojson.Safe.to_string)
          in
          Brtl_rspnc.create ~status:`Bad_request body
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id pr_opt dir page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.
            {
              user = Terrat_user.id user;
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

    let rspnc_of_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id pr_opt page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.
            { user = Terrat_user.id user; pull_request = pr_opt; storage; installation_id; limit }
        in
        Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx))
end

module Repos = struct
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

    let select_installation_repos_page () =
      Pgsql_io.Typed_sql.(
        sql
        // (* id *) Ret.bigint
        // (* installation_id *) Ret.bigint
        // (* name *) Ret.text
        // (* updated_at *) Ret.text
        /^ read "select_github_installation_repos_page.sql"
        /% Var.uuid "user_id"
        /% Var.bigint "installation_id"
        /% Var.(option (text "prev_name")))
  end

  let columns = Pgsql_pagination.Search.Col.[ create ~vname:"prev_name" ~cname:"name" ]

  module Page = struct
    type cursor = string

    type query = {
      user : Uuidm.t;
      storage : Terrat_storage.t;
      installation_id : int;
      dir : [ `Asc | `Desc ];
      limit : int;
    }

    type t = Terrat_api_components.Installation_repo.t Pgsql_pagination.t

    type err =
      [ Pgsql_pool.err
      | Pgsql_io.err
      ]

    let run_query ?cursor query f =
      let search = Pgsql_pagination.Search.(create ~page_size:query.limit ~dir:query.dir columns) in
      Pgsql_pool.with_conn query.storage ~f:(fun db ->
          f
            search
            db
            (Sql.select_installation_repos_page ())
            ~f:(fun id installation_id name updated_at ->
              {
                Terrat_api_components.Installation_repo.id = CCInt64.to_string id;
                installation_id = CCInt64.to_string installation_id;
                name;
                updated_at;
              })
            query.user
            (CCInt64.of_int query.installation_id)
            cursor)

    let next ?cursor query = run_query ?cursor query Pgsql_pagination.next
    let prev ?cursor query = run_query ?cursor query Pgsql_pagination.prev

    let to_yojson t =
      Terrat_api_installations.List_repos.Responses.OK.(
        { repositories = Pgsql_pagination.results t } |> to_yojson)

    let cursor_of_first t =
      let module R = Terrat_api_components.Installation_repo in
      match Pgsql_pagination.results t with
      | [] -> None
      | R.{ name; _ } :: _ -> Some [ name ]

    let cursor_of_last t =
      let module R = Terrat_api_components.Installation_repo in
      match CCList.rev (Pgsql_pagination.results t) with
      | [] -> None
      | R.{ name; _ } :: _ -> Some [ name ]

    let has_another_page t = Pgsql_pagination.has_next_page t

    let rspnc_of_err ~token = function
      | #Pgsql_pool.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_pool.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
      | #Pgsql_io.err as err ->
          Logs.err (fun m -> m "INSTALLATIONS : %s : ERROR : %a" token Pgsql_io.pp_err err);
          Brtl_rspnc.create ~status:`Internal_server_error ""
  end

  module Paginate = Brtl_ep_paginate.Make (Page)

  let get config storage installation_id page limit =
    Brtl_ep.run_result ~f:(fun ctx ->
        let open Abbs_future_combinators.Infix_result_monad in
        Terrat_session.with_session ctx
        >>= fun user ->
        Terrat_user.enforce_installation_access storage user installation_id ctx
        >>= fun () ->
        let open Abb.Future.Infix_monad in
        let query =
          Page.{ user = Terrat_user.id user; storage; installation_id; limit; dir = `Asc }
        in
        Paginate.run ?page ~page_param:"page" query ctx >>= fun ctx -> Abb.Future.return (Ok ctx))

  module Refresh = struct
    let chunk_size = 500

    module Sql = struct
      let insert_installation_repos () =
        Pgsql_io.Typed_sql.(
          sql
          /^ "insert into github_installation_repositories (id, installation_id, owner, name) \
              select * from unnest($id, $installation_id, $owner, $name) on conflict (id) do \
              nothing"
          /% Var.(array (bigint "id"))
          /% Var.(array (bigint "installation_id"))
          /% Var.(str_array (text "owner"))
          /% Var.(str_array (text "name")))
    end

    let refresh_repos request_id config storage installation_id task =
      let open Abb.Future.Infix_monad in
      Terrat_task.run storage task (fun () ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.get_installation_access_token config installation_id
          >>= fun access_token ->
          Terrat_github.with_client
            config
            (`Token access_token)
            Terrat_github.get_installation_repos
          >>= fun repositories ->
          let module R = Githubc2_components.Repository in
          let module Rp = R.Primary in
          let module U = Githubc2_components.Simple_user in
          let module Up = U.Primary in
          let installation_id = CCInt64.of_int installation_id in
          Abbs_future_combinators.List_result.iter
            ~f:(fun repositories ->
              Pgsql_pool.with_conn storage ~f:(fun db ->
                  Pgsql_io.Prepared_stmt.execute
                    db
                    (Sql.insert_installation_repos ())
                    (CCList.map
                       (fun R.{ primary = Rp.{ id; _ }; _ } -> CCInt64.of_int id)
                       repositories)
                    (CCList.replicate (CCList.length repositories) installation_id)
                    (CCList.map
                       (fun R.{ primary = Rp.{ owner = U.{ primary = Up.{ login; _ }; _ }; _ }; _ } ->
                         login)
                       repositories)
                    (CCList.map (fun R.{ primary = Rp.{ name; _ }; _ } -> name) repositories)))
            (CCList.chunks chunk_size repositories))
      >>= function
      | Ok () -> Abb.Future.return ()
      | Error (#Terrat_github.get_installation_access_token_err as err) ->
          Logs.err (fun m ->
              m
                "INSTALLATION : %s : REFRESH_REPOS : %a"
                request_id
                Terrat_github.pp_get_installation_access_token_err
                err);
          Abb.Future.return ()
      | Error (#Terrat_github.get_installation_repos_err as err) ->
          Logs.err (fun m ->
              m
                "INSTALLATION : %s : REFRESH_REPOS : %a"
                request_id
                Terrat_github.pp_get_installation_repos_err
                err);
          Abb.Future.return ()
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m ->
              m "INSTALLATION : %s : REFRESH_REPOS : %a" request_id Pgsql_pool.pp_err err);
          Abb.Future.return ()
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m ->
              m "INSTALLATION : %s : REFRESH_REPOS : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return ()

    let post config storage installation_id =
      Brtl_ep.run_result ~f:(fun ctx ->
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_session.with_session ctx
          >>= fun user ->
          Terrat_user.enforce_installation_access storage user installation_id ctx
          >>= fun () ->
          let task =
            Terrat_task.make ~name:(Printf.sprintf "INSTALLATION : REFRESH : %d" installation_id) ()
          in
          let open Abb.Future.Infix_monad in
          Pgsql_pool.with_conn storage ~f:(fun db -> Terrat_task.store db task)
          >>= function
          | Ok task ->
              Abb.Future.fork
                (refresh_repos (Brtl_ctx.token ctx) config storage installation_id task)
              >>= fun _ ->
              let id = Uuidm.to_string (Terrat_task.id task) in
              let body =
                Terrat_api_installations.Repo_refresh.Responses.OK.(
                  { id } |> to_yojson |> Yojson.Safe.to_string)
              in
              Abb.Future.return
                (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`OK body) ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m ->
                  m
                    "INSTALLATION : %s : REFRESH_REPOS : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_pool.pp_err
                    err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err) ->
              Logs.err (fun m ->
                  m
                    "INSTALLATION : %s : REFRESH_REPOS : %a"
                    (Brtl_ctx.token ctx)
                    Pgsql_io.pp_err
                    err);
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))
  end
end

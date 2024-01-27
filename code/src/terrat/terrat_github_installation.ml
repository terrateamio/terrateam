let chunk_size = 500

module Sql = struct
  let insert_installation_repos () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_installation_repositories (id, installation_id, owner, name) select * \
          from unnest($id, $installation_id, $owner, $name) on conflict (id) do nothing"
      /% Var.(array (bigint "id"))
      /% Var.(array (bigint "installation_id"))
      /% Var.(str_array (text "owner"))
      /% Var.(str_array (text "name")))
end

module Id = struct
  type t = int

  let make = CCFun.id
end

type refresh_repos_err =
  [ Terrat_github.get_installation_access_token_err
  | Terrat_github.get_installation_repos_err
  | Pgsql_pool.err
  | Pgsql_io.err
  ]
[@@deriving show]

type refresh_repos_err' =
  [ Pgsql_pool.err
  | Pgsql_io.err
  ]
[@@deriving show]

let refresh_repos ~request_id ~config ~storage installation_id =
  let open Abbs_future_combinators.Infix_result_monad in
  Terrat_github.get_installation_access_token config installation_id
  >>= fun access_token ->
  Terrat_github.with_client config (`Token access_token) Terrat_github.get_installation_repos
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
            (CCList.map (fun R.{ primary = Rp.{ id; _ }; _ } -> CCInt64.of_int id) repositories)
            (CCList.replicate (CCList.length repositories) installation_id)
            (CCList.map
               (fun R.{ primary = Rp.{ owner = U.{ primary = Up.{ login; _ }; _ }; _ }; _ } ->
                 login)
               repositories)
            (CCList.map (fun R.{ primary = Rp.{ name; _ }; _ } -> name) repositories)))
    (CCList.chunks chunk_size repositories)

let refresh_repos_task request_id config storage installation_id task =
  let open Abb.Future.Infix_monad in
  Terrat_task.run storage task (fun () ->
      refresh_repos ~request_id ~config ~storage installation_id)
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
      Logs.err (fun m -> m "INSTALLATION : %s : REFRESH_REPOS : %a" request_id Pgsql_io.pp_err err);
      Abb.Future.return ()

let refresh_repos' ~request_id ~config ~storage installation_id =
  Logs.debug (fun m -> m "INSTALLATION : %s : REPO_REFRESH : %d" request_id installation_id);
  let task =
    Terrat_task.make
      ~name:(Printf.sprintf "INSTALLATION : %s : REPO_REFRESH : %d" request_id installation_id)
      ()
  in
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db -> Terrat_task.store db task)
  >>= fun task ->
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.ignore
    (Abb.Future.fork (refresh_repos_task request_id config storage installation_id task))
  >>= fun () -> Abb.Future.return (Ok task)

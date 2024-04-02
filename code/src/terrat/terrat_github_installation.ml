let terrateam_github_action_workflow_path = ".github/workflows/terrateam.yml"
let chunk_size = 500

module Sql = struct
  let insert_installation_repos () =
    Pgsql_io.Typed_sql.(
      sql
      /^ "insert into github_installation_repositories (id, installation_id, owner, name, setup) \
          select * from unnest($id, $installation_id, $owner, $name, $setup) on conflict (id) do \
          update set (installation_id, owner, name, setup) = (excluded.installation_id, \
          excluded.owner, excluded.name, excluded.setup)"
      /% Var.(array (bigint "id"))
      /% Var.(array (bigint "installation_id"))
      /% Var.(str_array (text "owner"))
      /% Var.(str_array (text "name"))
      /% Var.(array (boolean "setup")))
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
  let client = Terrat_github.create config (`Token access_token) in
  Terrat_github.get_installation_repos client
  >>= fun repositories ->
  let module R = Githubc2_components.Repository in
  let module Rp = R.Primary in
  let module U = Githubc2_components.Simple_user in
  let module Up = U.Primary in
  let open Abb.Future.Infix_monad in
  Abbs_future_combinators.List.map
    ~f:(fun
        {
          R.primary =
            {
              R.Primary.owner = { U.primary = { U.Primary.login = owner; _ }; _ };
              name = repo;
              default_branch;
              _;
            };
          _;
        }
      ->
      Terrat_github.fetch_file
        ~owner
        ~repo
        ~ref_:default_branch
        ~path:terrateam_github_action_workflow_path
        client
      >>= function
      | Ok (Some _) -> Abb.Future.return true
      | Ok None -> Abb.Future.return false
      | Error (#Terrat_github.fetch_file_err as err) ->
          Logs.err (fun m ->
              m
                "INSTALLATION : %s : REFRESH_REPOS : FETCH_FILE : %a"
                request_id
                Terrat_github.pp_fetch_file_err
                err);
          Abb.Future.return false)
    repositories
  >>= fun repos_setup ->
  let installation_id = CCInt64.of_int installation_id in
  Abbs_future_combinators.List_result.iter
    ~f:(fun (repositories, repos_setup) ->
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
            (CCList.map (fun R.{ primary = Rp.{ name; _ }; _ } -> name) repositories)
            repos_setup))
    (CCList.combine (CCList.chunks chunk_size repositories) (CCList.chunks chunk_size repos_setup))

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

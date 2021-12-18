(* module Gw = Githubc2_webhooks
 * 
 * module Sql = struct
 *   let read fname = CCOpt.get_exn_or fname (Terrat_files_sql.read fname)
 * 
 *   let insert_org =
 *     Pgsql_io.Typed_sql.(sql // (\* id *\) Ret.uuid /^ read "insert_org.sql" /% Var.text "name")
 * 
 *   let insert_github_installation =
 *     Pgsql_io.Typed_sql.(
 *       sql
 *       /^ read "insert_github_installation.sql"
 *       /% Var.bigint "id"
 *       /% Var.text "login"
 *       /% Var.uuid "org"
 *       /% Var.text "target_type")
 * 
 *   let select_github_installation =
 *     Pgsql_io.Typed_sql.(
 *       sql
 *       // (\* id *\) Ret.bigint
 *       /^ "select id from github_installations where id = $id"
 *       /% Var.bigint "id")
 * 
 *   let insert_github_installation_repository =
 *     Pgsql_io.Typed_sql.(
 *       sql
 *       /^ read "insert_github_installation_repository.sql"
 *       /% Var.bigint "id"
 *       /% Var.bigint "installation_id"
 *       /% Var.text "name"
 *       /% Var.text "owner")
 * 
 *   let insert_github_workflow_manifest =
 *     Pgsql_io.Typed_sql.(
 *       sql
 *       // (\* id *\) Ret.uuid
 *       /^ read "insert_github_work_manifest.sql"
 *       /% Var.text "base_sha"
 *       /% Var.text "branch"
 *       /% Var.bigint "pull_number"
 *       /% Var.bigint "repository"
 *       /% Var.text "run_type"
 *       /% Var.text "tag_query")
 * end
 * 
 * type t =
 *   | Debug of string
 *   | Comment of {
 *       installation_id : int;
 *       owner : string;
 *       repo : string;
 *       pull_number : int;
 *       msg : string;
 *     }
 *   | Installation_create of Githubc2_webhooks.Installation.t
 *   | Github_action_run of Terrat_github_action_runner.t
 * 
 * let create_github_installation db installation =
 *   let open Abbs_future_combinators.Infix_result_monad in
 *   Pgsql_io.Prepared_stmt.fetch
 *     db
 *     Sql.select_github_installation
 *     ~f:CCFun.id
 *     (CCInt64.of_int installation.Gw.Installation.id)
 *   >>= function
 *   | [] -> (
 *       Pgsql_io.Prepared_stmt.fetch
 *         db
 *         Sql.insert_org
 *         ~f:CCFun.id
 *         installation.Gw.Installation.account.Gw.User.login
 *       >>= function
 *       | org_id :: _ ->
 *           Pgsql_io.Prepared_stmt.execute
 *             db
 *             Sql.insert_github_installation
 *             (Int64.of_int installation.Gw.Installation.id)
 *             installation.Gw.Installation.account.Gw.User.login
 *             org_id
 *             installation.Gw.Installation.account.Gw.User.type_
 *       | [] -> assert false)
 *   | _ :: _ -> Abb.Future.return (Ok ())
 * 
 * let comment_on_pull_request ~config ~installation_id ~owner ~repo ~pull_number msg =
 *   let open Abbs_future_combinators.Infix_result_monad in
 *   Terrat_github.get_installation_access_token config installation_id
 *   >>= fun token ->
 *   let client = Terrat_github.create (`Token token) in
 *   Githubc2_abb.call
 *     client
 *     Githubc2_issues.Create_comment.(
 *       make
 *         ~body:Request_body.(make Primary.{ body = msg })
 *         (Parameters.make ~issue_number:pull_number ~owner ~repo))
 *   >>= fun resp ->
 *   match Openapi.Response.value resp with
 *   | `Created _ -> Abb.Future.return (Ok ())
 *   | `Forbidden _ | `Gone _ | `Not_found _ | `Unprocessable_entity _ ->
 *       Abb.Future.return (Error `Forbidden)
 * 
 * let run_github_action
 *     config
 *     db
 *     installation_id
 *     repository
 *     pull_number
 *     base_sha
 *     branch
 *     run_type
 *     tag_query =
 *   let open Abbs_future_combinators.Infix_result_monad in
 *   Terrat_github.get_installation_access_token config installation_id
 *   >>= fun access_token ->
 *   Terrat_github_action.load_workflow
 *     ~access_token
 *     ~owner:repository.Gw.Repository.owner.Gw.User.login
 *     ~repo:repository.Gw.Repository.name
 *   >>= function
 *   | Some workflow_id ->
 *       Pgsql_io.tx db ~f:(fun () ->
 *           Pgsql_io.Prepared_stmt.execute
 *             db
 *             Sql.insert_github_installation_repository
 *             (CCInt64.of_int repository.Gw.Repository.id)
 *             (CCInt64.of_int installation_id)
 *             repository.Gw.Repository.name
 *             repository.Gw.Repository.owner.Gw.User.login
 *           >>= fun () ->
 *           Pgsql_io.Prepared_stmt.fetch
 *             db
 *             Sql.insert_github_workflow_manifest
 *             ~f:CCFun.id
 *             base_sha
 *             branch
 *             (CCInt64.of_int pull_number)
 *             (CCInt64.of_int repository.Gw.Repository.id)
 *             (match run_type with
 *             | `Autoplan -> "autoplan"
 *             | `Plan -> "plan"
 *             | `Apply -> "apply")
 *             (Terrat_tag_set.to_string tag_query)
 *           >>= function
 *           | [] -> assert false
 *           | run_id :: _ ->
 *               let client = Terrat_github.create (`Token access_token) in
 *               Githubc2_abb.call
 *                 client
 *                 Githubc2_actions.Create_workflow_dispatch.(
 *                   make
 *                     ~body:
 *                       Request_body.
 *                         {
 *                           primary =
 *                             Primary.
 *                               {
 *                                 ref_ = branch;
 *                                 inputs =
 *                                   Some
 *                                     Inputs.
 *                                       {
 *                                         primary = Json_schema.Empty_obj.t;
 *                                         additional =
 *                                           Json_schema.String_map.of_list
 *                                             [
 *                                               ("work-token", Uuidm.to_string run_id);
 *                                               ("api-base-url", Terrat_config.api_base config);
 *                                             ];
 *                                       };
 *                               };
 *                           additional = Json_schema.String_map.empty;
 *                         }
 *                     Parameters.(
 *                       make
 *                         ~owner:repository.Gw.Repository.owner.Gw.User.login
 *                         ~repo:repository.Gw.Repository.name
 *                         ~workflow_id:(Workflow_id.V0 workflow_id)))
 *               >>= fun _ -> Abb.Future.return (Ok `Ran))
 *   | None -> Abb.Future.return (Ok `No_workflow_in_repo)
 * 
 * let run ~config ~storage ~token ops =
 *   let open Abb.Future.Infix_monad in
 *   Pgsql_pool.with_conn storage ~f:(fun db ->
 *       Pgsql_io.tx db ~f:(fun () ->
 *           Abbs_future_combinators.List_result.iter
 *             ~f:(function
 *               | Debug msg ->
 *                   Logs.debug (fun m -> m "POLICY_EXEC : %s : DEBUG : %s" token msg);
 *                   Abb.Future.return (Ok ())
 *               | Comment { installation_id; owner; repo; pull_number; msg } ->
 *                   Logs.debug (fun m ->
 *                       m
 *                         "POLICY_EXEC : %s : COMMENT : %d : %s : %s : %d : %s"
 *                         token
 *                         installation_id
 *                         owner
 *                         repo
 *                         pull_number
 *                         msg);
 *                   comment_on_pull_request ~config ~installation_id ~owner ~repo ~pull_number msg
 *               | Installation_create installation ->
 *                   Logs.debug (fun m ->
 *                       m
 *                         "POLICY_EXEC : %s : INSTALLATION_CREATE : %d"
 *                         token
 *                         installation.Gw.Installation.id);
 *                   create_github_installation db installation
 *               | Github_action_run
 *                   {
 *                     Terrat_github_action_runner.base_sha;
 *                     branch;
 *                     installation_id;
 *                     pull_number;
 *                     repository;
 *                     run_type;
 *                     tag_query;
 *                   } -> (
 *                   let open Abbs_future_combinators.Infix_result_monad in
 *                   Logs.debug (fun m ->
 *                       m
 *                         "POLICY_EXEC : %s : GITHUB_ACTION_RUN : %d : %s : %s : %d : %s : %s"
 *                         token
 *                         installation_id
 *                         repository.Gw.Repository.owner.Gw.User.login
 *                         repository.Gw.Repository.name
 *                         pull_number
 *                         base_sha
 *                         branch);
 *                   run_github_action
 *                     config
 *                     db
 *                     installation_id
 *                     repository
 *                     pull_number
 *                     base_sha
 *                     branch
 *                     run_type
 *                     tag_query
 *                   >>= function
 *                   | `Ran ->
 *                       Logs.debug (fun m -> m "POLICY_EXEC : %s : RAN_GITHUB_ACTION" token);
 *                       Abb.Future.return (Ok ())
 *                   | `No_workflow_in_repo ->
 *                       Logs.debug (fun m ->
 *                           m
 *                             "POLICY_EXEC : %s : NO_WORKFLOW_EXISTS_IN_REPO : %d : %s : %s : %d"
 *                             token
 *                             installation_id
 *                             repository.Gw.Repository.owner.Gw.User.login
 *                             repository.Gw.Repository.name
 *                             pull_number);
 *                       Abb.Future.return (Ok ())))
 *             ops))
 *   >>= function
 *   | Ok () -> Abb.Future.return ()
 *   | Error (#Pgsql_pool.err as err) ->
 *       Logs.err (fun m -> m "POLICY_EXEC : %s : ERROR : %s" token (Pgsql_pool.show_err err));
 *       Abb.Future.return ()
 *   | Error (#Pgsql_io.err as err) ->
 *       Logs.err (fun m -> m "POLICY_EXEC : %s : ERROR : %s" token (Pgsql_io.show_err err));
 *       Abb.Future.return ()
 *   | Error (#Githubc2_abb.call_err as err) ->
 *       Logs.err (fun m -> m "POLICY_EXEC : %s : ERROR : %s" token (Githubc2_abb.show_call_err err));
 *       Abb.Future.return ()
 *   | Error `Forbidden ->
 *       Logs.err (fun m -> m "POLICY_EXEC : %s : ERROR : FORBIDDEN" token);
 *       Abb.Future.return () *)

module Sql = struct
  let read fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let select_installation_config =
    Pgsql_io.Typed_sql.(
      sql
      // (* allow_draft_pr *) Ret.boolean
      // (* auto_merge_after_apply *) Ret.boolean
      // (* autoplan_file_list *) Ret.varchar
      // (* default_terraform_version *) Ret.(option varchar)
      // (* enable_apply *) Ret.boolean
      // (* enable_apply_all *) Ret.boolean
      // (* enable_autoplan *) Ret.boolean
      // (* enable_diff_markdown_format *) Ret.boolean
      // (* enable_local_merge_dest_branch_before_plan *) Ret.boolean
      // (* enable_repo_locking *) Ret.boolean
      // (* enable_terragrunt *) Ret.boolean
      // (* require_approval *) Ret.boolean
      // (* require_mergeable *) Ret.boolean
      // (* updated_at *) Ret.varchar
      // (* updated_by *) Ret.(option varchar)
      /^ read "select_installation_config.sql"
      /% Var.bigint "installation_id"
      /% Var.(option (varchar "user_id")))

  let select_installation_secret =
    Pgsql_io.Typed_sql.(
      sql
      // (* secret *) Ret.uuid
      /^ read "select_installation_secret.sql"
      /% Var.bigint "installation_id")

  let insert_installation_config_defaults =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_installation_config_defaults.sql"
      /% Var.bigint "installation_id"
      /% Var.(option (varchar "user_id")))
end

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let rec get_config storage installation_id =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch db Sql.select_installation_secret ~f:CCFun.id installation_id
      >>= function
      | secret :: _ ->
          Pgsql_io.Prepared_stmt.fetch
            db
            Sql.select_installation_config
            ~f:
              (fun allow_draft_pr
                   auto_merge_after_apply
                   autoplan_file_list
                   default_terraform_version
                   enable_apply
                   enable_apply_all
                   enable_autoplan
                   enable_diff_markdown_format
                   enable_local_merge_dest_branch_before_plan
                   enable_repo_locking
                   enable_terragrunt
                   require_approval
                   require_mergeable
                   updated_at
                   _updated_by ->
              Terrat_data_backend.Response.Config.
                {
                  allow_draft_pr;
                  auto_merge_after_apply;
                  autoplan_file_list = CCString.split_on_char ',' autoplan_file_list;
                  default_terraform_version;
                  enable_apply;
                  enable_apply_all;
                  enable_autoplan;
                  enable_diff_markdown_format;
                  enable_local_merge_dest_branch_before_plan;
                  enable_repo_locking;
                  enable_terragrunt;
                  require_approval;
                  require_mergeable;
                  updated_at;
                  webhook_secret = Uuidm.to_string secret;
                })
            installation_id
            None
      | []          -> assert false)
  >>= function
  | config :: _ -> Abb.Future.return (Ok config)
  | []          ->
      (* Not there, so insert it and query again *)
      Pgsql_pool.with_conn storage ~f:(fun db ->
          (* Add it with None user as this is really just inserting the defaults *)
          Pgsql_io.Prepared_stmt.execute
            db
            Sql.insert_installation_config_defaults
            installation_id
            None)
      >>= fun () -> get_config storage installation_id

let get storage ctx =
  let open Abb.Future.Infix_monad in
  let request = Brtl_ctx.request ctx in
  let headers = Brtl_ctx.Request.headers request in
  Terrat_verify_jwt.verify storage headers
  >>= function
  | Ok (_, _, _, installation_id) -> (
      get_config storage installation_id
      >>= function
      | Ok config                      ->
          let body =
            config |> Terrat_data_backend.Response.Config.to_yojson |> Yojson.Safe.to_string
          in
          Abb.Future.return
            (Brtl_ctx.set_response
               (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
               ctx)
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "CONFIG : GET : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)
      | Error (#Pgsql_io.err as err)   ->
          Logs.err (fun m -> m "CONFIG : GET : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
  | Error (#Terrat_verify_jwt.err as err) ->
      Logs.err (fun m -> m "BACKEND_SECRETS : GET : FAILED : %s" (Terrat_verify_jwt.show_err err));
      Abb.Future.return (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Bad_request "") ctx)

module Gh = Githubc_v3

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
      // (* update_at *) Ret.varchar
      // (* updated_by *) Ret.(option varchar)
      /^ read "select_installation_config.sql"
      /% Var.bigint "installation_id"
      /% Var.varchar "user_id")

  let insert_installation_config =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_installation_config.sql"
      /% Var.bigint "installation_id"
      /% Var.boolean "allow_draft_pr"
      /% Var.boolean "auto_merge_after_apply"
      /% Var.varchar "autoplan_file_list"
      /% Var.(option (varchar "default_terraform_version"))
      /% Var.boolean "enable_apply"
      /% Var.boolean "enable_apply_all"
      /% Var.boolean "enable_autoplan"
      /% Var.boolean "enable_diff_markdown_format"
      /% Var.boolean "enable_local_merge_dest_branch_before_plan"
      /% Var.boolean "enable_repo_locking"
      /% Var.boolean "enable_terragrunt"
      /% Var.boolean "require_approval"
      /% Var.boolean "require_mergeable"
      /% Var.varchar "user_id")

  let insert_installation_config_defaults =
    Pgsql_io.Typed_sql.(
      sql
      /^ read "insert_installation_config_defaults.sql"
      /% Var.bigint "installation_id"
      /% Var.(option (varchar "user_id")))
end

let response_headers = Cohttp.Header.of_list [ ("content-type", "application/json") ]

let apply v f c =
  match v with
    | Some v -> f v c
    | None   -> c

let apply_opt_opt v f c =
  (* Because JSON cannot represents ['a option option] we use that is the
     default value if no value was input *)
  match v with
    | Some None -> c
    | Some v    -> f v c
    | None      -> f None c

let merge_config_update config config_update =
  let module C = Terrat_data.Response.Config in
  let module R = Terrat_data.Request.Config in
  let cu = config_update in
  config
  |> apply cu.R.allow_draft_pr (fun v c -> C.{ c with allow_draft_pr = v })
  |> apply cu.R.auto_merge_after_apply (fun v c -> C.{ c with auto_merge_after_apply = v })
  |> apply cu.R.autoplan_file_list (fun v c -> C.{ c with autoplan_file_list = v })
  |> apply_opt_opt cu.R.default_terraform_version (fun v c ->
         C.{ c with default_terraform_version = v })
  |> apply cu.R.enable_apply (fun v c -> C.{ c with enable_apply = v })
  |> apply cu.R.enable_apply_all (fun v c -> C.{ c with enable_apply_all = v })
  |> apply cu.R.enable_autoplan (fun v c -> C.{ c with enable_autoplan = v })
  |> apply cu.R.enable_diff_markdown_format (fun v c ->
         C.{ c with enable_diff_markdown_format = v })
  |> apply cu.R.enable_local_merge_dest_branch_before_plan (fun v c ->
         C.{ c with enable_local_merge_dest_branch_before_plan = v })
  |> apply cu.R.enable_repo_locking (fun v c -> C.{ c with enable_repo_locking = v })
  |> apply cu.R.enable_terragrunt (fun v c -> C.{ c with enable_terragrunt = v })
  |> apply cu.R.require_approval (fun v c -> C.{ c with require_approval = v })
  |> apply cu.R.require_mergeable (fun v c -> C.{ c with require_mergeable = v })

let rec get_config storage installation_id user_id =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
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
               updated_by ->
          Terrat_data.Response.Config.
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
              updated_by;
            })
        installation_id
        user_id)
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
      >>= fun () -> get_config storage installation_id user_id

let update_config storage installation_id user_id installation_config_update =
  let open Abbs_future_combinators.Infix_result_monad in
  get_config storage installation_id user_id
  >>= fun config ->
  let config = merge_config_update config installation_config_update in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      let module C = Terrat_data.Response.Config in
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_installation_config
        installation_id
        config.C.allow_draft_pr
        config.C.auto_merge_after_apply
        (CCString.concat "," config.C.autoplan_file_list)
        config.C.default_terraform_version
        config.C.enable_apply
        config.C.enable_apply_all
        config.C.enable_autoplan
        config.C.enable_diff_markdown_format
        config.C.enable_local_merge_dest_branch_before_plan
        config.C.enable_repo_locking
        config.C.enable_terragrunt
        config.C.require_approval
        config.C.require_mergeable
        user_id)
  >>= fun () -> get_config storage installation_id user_id

let get config storage github_schema installation_id =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.verify_user_installation_access
        config
        storage
        github_schema
        installation_id
        user_id
      >>= function
      | Ok () -> (
          get_config storage installation_id user_id
          >>= function
          | Ok config                      ->
              let body = config |> Terrat_data.Response.Config.to_yojson |> Yojson.Safe.to_string in
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response
                      (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                      ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "CONFIG : GET : ERROR : DB : %s" (Pgsql_pool.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err)   ->
              Logs.err (fun m -> m "CONFIG : GET : ERROR : DB : %s" (Pgsql_io.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          )
      | Error `Forbidden ->
          Logs.info (fun m -> m "CONFIG : GET : FORBIDDEN : %s : %Ld" user_id installation_id);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "CONFIG : GET : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "CONFIG : GET : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Gh.call_err as err) ->
          Logs.err (fun m -> m "CONFIG : GET : ERROR : GITHUB : %s" (Gh.show_call_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Terrat_github.get_access_token_err as err) ->
          Logs.err (fun m ->
              m "CONFIG : GET : ERROR : GITHUB : %s" (Terrat_github.show_get_access_token_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

let put config storage github_schema installation_id installation_config_update =
  Brtl_ep.run_result ~f:(fun ctx ->
      let open Abbs_future_combinators.Infix_result_monad in
      Terrat_session.with_session ctx
      >>= fun user_id ->
      let open Abb.Future.Infix_monad in
      Terrat_github.verify_admin_installation_access
        config
        storage
        github_schema
        installation_id
        user_id
      >>= function
      | Ok () -> (
          update_config storage installation_id user_id installation_config_update
          >>= function
          | Ok config                      ->
              let body = config |> Terrat_data.Response.Config.to_yojson |> Yojson.Safe.to_string in
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response
                      (Brtl_rspnc.create ~headers:response_headers ~status:`OK body)
                      ctx))
          | Error (#Pgsql_pool.err as err) ->
              Logs.err (fun m -> m "CONFIG : PUT : ERROR : DB : %s" (Pgsql_pool.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          | Error (#Pgsql_io.err as err)   ->
              Logs.err (fun m -> m "CONFIG : PUT : ERROR : DB : %s" (Pgsql_io.show_err err));
              Abb.Future.return
                (Ok
                   (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
          )
      | Error `Forbidden ->
          Logs.info (fun m -> m "CONFIG : PUT : FORBIDDEN : %s : %Ld" user_id installation_id);
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Forbidden "") ctx))
      | Error (#Pgsql_pool.err as err) ->
          Logs.err (fun m -> m "CONFIG : PUT : ERROR : DB : %s" (Pgsql_pool.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "CONFIG : PUT : ERROR : DB : %s" (Pgsql_io.show_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Gh.call_err as err) ->
          Logs.err (fun m -> m "CONFIG : PUT : ERROR : GITHUB : %s" (Gh.show_call_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx))
      | Error (#Terrat_github.get_access_token_err as err) ->
          Logs.err (fun m ->
              m "CONFIG : PUT : ERROR : GITHUB : %s" (Terrat_github.show_get_access_token_err err));
          Abb.Future.return
            (Ok (Brtl_ctx.set_response (Brtl_rspnc.create ~status:`Internal_server_error "") ctx)))

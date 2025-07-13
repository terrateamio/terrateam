module String_map = CCMap.Make (CCString)
module String_set = CCSet.Make (CCString)

let src = Logs.Src.create "vcs_service_github_oss"

module Logs = (val Logs.src_log src : Logs.LOG)

module Provider :
  Terrat_vcs_provider2_github.S
    with type Api.Config.t = Terrat_vcs_service_github_provider.Api.Config.t = struct
  module Api = Terrat_vcs_api_github
  module Unlock_id = Terrat_vcs_service_github_provider.Unlock_id
  module Db = Terrat_vcs_service_github_provider.Db
  module Apply_requirements = Terrat_vcs_service_github_provider.Apply_requirements
  module Tier = Terrat_vcs_service_github_provider.Tier

  (* Order matters here.  Roles closer to the beginning of the search are more
         powerful than those closer to the end *)
  let repo_permission_levels =
    [
      ("admin", "admin");
      ("maintain", "maintain");
      ("write", "write");
      ("triage", "triage");
      ("read", "read");
    ]

  let match_user ~request_id client repo user =
    let module M = Terrat_base_repo_config_v1.Access_control.Match in
    function
    | M.User value -> Abb.Future.return (Ok (CCString.equal value user))
    | M.Team value -> (
        let open Abb.Future.Infix_monad in
        Api.is_member_of_team ~request_id ~team:value ~user:(Api.User.make user) repo client
        >>= function
        | Ok res -> Abb.Future.return (Ok res)
        | Error _ -> Abb.Future.return (Error `Error))
    | M.Role value -> (
        let open Abb.Future.Infix_monad in
        match CCList.find_idx CCFun.(fst %> CCString.equal value) repo_permission_levels with
        | Some (idx, _) -> (
            Api.get_repo_role ~request_id repo (Api.User.make user) client
            >>= function
            | Ok (Some role) -> (
                match CCList.find_idx CCFun.(snd %> CCString.equal role) repo_permission_levels with
                | Some (idx_role, _) ->
                    (* Test if their actual role has an index less than or
                           equal to the index of the role in the query. *)
                    Abb.Future.return (Ok (idx_role <= idx))
                | None -> Abb.Future.return (Ok false))
            | Ok None -> Abb.Future.return (Ok false)
            | Error _ -> Abb.Future.return (Error `Error))
        | None -> raise (Failure "nyi")
        (* Abb.Future.return (Error (`Invalid_query query)) *))
    | M.Any -> Abb.Future.return (Ok true)

  module Gate = struct
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
             (Terrat_files_github_sql.read fname))

      let gate =
        CCFun.(
          CCOption.wrap Yojson.Safe.from_string
          %> CCOption.map Terrat_gate.of_yojson
          %> CCOption.flat_map CCResult.to_opt)

      let insert_gate_approval =
        Pgsql_io.Typed_sql.(
          sql
          /^ read "insert_gate_approval.sql"
          /% Var.text "approver"
          /% Var.text "token"
          /% Var.bigint "repository"
          /% Var.bigint "pull_number"
          /% Var.text "sha")

      let select_gate_approvals =
        Pgsql_io.Typed_sql.(
          sql
          //
          (* token *)
          Ret.text
          //
          (* approver *)
          Ret.text
          /^ read "select_gate_approvals.sql"
          /% Var.bigint "repository"
          /% Var.bigint "pull_number")

      let select_gates =
        Pgsql_io.Typed_sql.(
          sql
          //
          (* token *)
          Ret.text
          //
          (* gate *)
          Ret.ud' gate
          //
          (* dir *)
          Ret.text
          //
          (* workspace *)
          Ret.text
          /^ read "select_gates.sql"
          /% Var.bigint "repository"
          /% Var.bigint "pull_number"
          /% Var.(str_array (text "dirs"))
          /% Var.(str_array (text "workspaces")))
    end

    let add_approval ~request_id ~token ~approver pull_request db =
      let open Abb.Future.Infix_monad in
      let repo_id = CCInt64.of_int @@ Api.Repo.id @@ Terrat_pull_request.repo pull_request in
      let pull_number = CCInt64.of_int @@ Terrat_pull_request.id pull_request in
      let sha = Api.Ref.to_string @@ Terrat_pull_request.branch_ref pull_request in
      Pgsql_io.Prepared_stmt.execute
        db
        Sql.insert_gate_approval
        approver
        token
        repo_id
        pull_number
        sha
      >>= function
      | Ok () -> Abb.Future.return (Ok ())
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "%s : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)

    let eval ~request_id client dirspaces pull_request db =
      let module Match_set = CCSet.Make (Terrat_base_repo_config_v1.Access_control.Match) in
      let module Match_map = CCMap.Make (Terrat_base_repo_config_v1.Access_control.Match) in
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        let repo = Terrat_pull_request.repo pull_request in
        let repo_id = CCInt64.of_int @@ Api.Repo.id @@ Terrat_pull_request.repo pull_request in
        let pull_number = CCInt64.of_int @@ Terrat_pull_request.id pull_request in
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_gate_approvals
          ~f:(fun token approver -> (token, approver))
          repo_id
          pull_number
        >>= fun approvers ->
        CCList.iter
          (fun (token, approver) ->
            Logs.info (fun m ->
                m "%s : CHECK_GATE : token=%s : approver=%s" request_id token approver))
          approvers;
        let approvers_map =
          CCList.fold_left
            (fun acc (token, approver) -> String_map.add_to_list token approver acc)
            String_map.empty
            approvers
        in
        Pgsql_io.Prepared_stmt.fetch
          db
          Sql.select_gates
          ~f:(fun token gate dir workspace -> (token, gate, { Terrat_dirspace.dir; workspace }))
          repo_id
          pull_number
          (CCList.map (fun { Terrat_dirspace.dir; _ } -> dir) dirspaces)
          (CCList.map (fun { Terrat_dirspace.workspace; _ } -> workspace) dirspaces)
        >>= fun gates ->
        let gates_map =
          Terrat_data.Dirspace_map.to_list
          @@ CCList.fold_left
               (fun acc (token, gate, dirspace) ->
                 Terrat_data.Dirspace_map.add_to_list dirspace (token, gate) acc)
               Terrat_data.Dirspace_map.empty
               gates
        in
        let all_queries =
          Match_set.to_list
          @@ Match_set.of_list
          @@ CCList.flat_map
               (fun (_, gates) ->
                 CCList.flat_map
                   (fun (_, { Terrat_gate.all_of; any_of; any_of_count = _ }) -> all_of @ any_of)
                   gates)
               gates_map
        in
        Abbs_future_combinators.List_result.map
          ~f:(fun q ->
            Abbs_future_combinators.List_result.map
              ~f:(fun (_, approver) ->
                match_user ~request_id client repo approver q
                >>= function
                | true -> Abb.Future.return (Ok (Some approver))
                | false -> Abb.Future.return (Ok None))
              approvers
            >>= fun res ->
            let res = CCList.filter_map CCFun.id res in
            Abb.Future.return (Ok (q, res)))
          all_queries
        >>= fun query_results ->
        let query_to_users = Match_map.of_list query_results in
        Abb.Future.return
          (Ok
             (CCList.flat_map
                (fun (dirspace, gates) ->
                  CCList.filter_map
                    (fun (token, { Terrat_gate.all_of; any_of; any_of_count }) ->
                      let { Terrat_dirspace.dir; workspace } = dirspace in
                      Logs.info (fun m ->
                          m
                            "%s : GATE : dir=%s : workspace=%s : token=%s : all_of=%s"
                            request_id
                            dir
                            workspace
                            token
                            (CCString.concat " " @@ CCList.map Terrat_gate.Match.to_string all_of));
                      Logs.info (fun m ->
                          m
                            "%s : GATE : dir=%s : workspace=%s : token=%s : any_of=%s"
                            request_id
                            dir
                            workspace
                            token
                            (CCString.concat " " @@ CCList.map Terrat_gate.Match.to_string any_of));
                      Logs.info (fun m ->
                          m
                            "%s : GATE : dir=%s : workspace=%s : token=%s : any_of_count=%d"
                            request_id
                            dir
                            workspace
                            token
                            any_of_count);
                      let token_approvers =
                        String_set.of_list
                        @@ CCOption.get_or ~default:[]
                        @@ String_map.find_opt token approvers_map
                      in
                      (* A map of query to users who have approved that token.
                         An empty list for the query means that it has not been
                         approved by anyone. *)
                      let all_of =
                        CCList.map
                          (fun m ->
                            ( m,
                              CCList.filter CCFun.(flip String_set.mem token_approvers)
                              @@ CCOption.get_or ~default:[]
                              @@ Match_map.find_opt m query_to_users ))
                          all_of
                      in
                      (* Set of users that have approved the token for the any_of matches. *)
                      let any_of_set =
                        String_set.of_list
                        @@ CCList.filter CCFun.(flip String_set.mem token_approvers)
                        @@ CCList.flat_map
                             CCFun.(
                               flip Match_map.find_opt query_to_users %> CCOption.get_or ~default:[])
                             any_of
                      in
                      let passed =
                        CCList.for_all CCFun.(snd %> CCList.is_empty %> not) all_of
                        && any_of_count <= String_set.cardinal any_of_set
                      in
                      let all_of =
                        CCList.filter_map
                          (function
                            | q, [] -> Some q
                            | q, _ -> None)
                          all_of
                      in
                      let result =
                        {
                          Terrat_gate.all_of;
                          any_of;
                          any_of_count = CCInt.max 0 (any_of_count - String_set.cardinal any_of_set);
                        }
                      in
                      Logs.info (fun m ->
                          m
                            "%s : GATE : RESULT : dir=%s : workspace=%s : token=%s : all_of=%s"
                            request_id
                            dir
                            workspace
                            token
                            (CCString.concat " " @@ CCList.map Terrat_gate.Match.to_string all_of));
                      Logs.info (fun m ->
                          m
                            "%s : GATE : RESULT: dir=%s : workspace=%s : token=%s : any_of=%s"
                            request_id
                            dir
                            workspace
                            token
                            (CCString.concat " " @@ CCList.map Terrat_gate.Match.to_string any_of));
                      Logs.info (fun m ->
                          m
                            "%s : GATE : RESULT : dir=%s : workspace=%s : token=%s : \
                             any_of_count=%d"
                            request_id
                            dir
                            workspace
                            token
                            any_of_count);
                      Logs.info (fun m ->
                          m
                            "%s : GATE : RESULT : dir=%s : workspace=%s : token=%s : passed=%s"
                            request_id
                            dir
                            workspace
                            token
                            (Bool.to_string passed));
                      if passed then None
                      else
                        Some
                          {
                            Terrat_vcs_provider2.Gate_eval.dirspace =
                              (if
                                 Terrat_dirspace.equal
                                   dirspace
                                   { Terrat_dirspace.dir = ""; workspace = "" }
                               then None
                               else Some dirspace);
                            token;
                            result;
                          })
                    gates)
                gates_map))
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok res -> Abb.Future.return (Ok res)
      | Error (#Pgsql_io.err as err) ->
          Logs.err (fun m -> m "%s : %a" request_id Pgsql_io.pp_err err);
          Abb.Future.return (Error `Error)
      | Error `Error ->
          Logs.err (fun m -> m "%s" request_id);
          Abb.Future.return (Error `Error)
  end

  module Work_manifest = Terrat_vcs_service_github_provider.Work_manifest

  module Repo_config = struct
    let fetch_repo_config_file request_id client repo ref_ basename =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun yml yaml ->
          match (yml, yaml) with
          | Some yml, _ ->
              Some
                ( Api.Repo.to_string repo ^ ":" ^ Api.Ref.to_string ref_ ^ ":" ^ basename ^ ".yml",
                  yml )
          | _, Some yaml ->
              Some
                ( Api.Repo.to_string repo ^ ":" ^ Api.Ref.to_string ref_ ^ ":" ^ basename ^ ".yaml",
                  yaml )
          | _, _ -> None)
        <$> Api.fetch_file ~request_id client repo ref_ (basename ^ ".yml")
        <*> Api.fetch_file ~request_id client repo ref_ (basename ^ ".yaml"))
      >>= function
      | None -> Abb.Future.return (Ok None)
      | Some (_, content) when CCString.is_empty (CCString.trim content) ->
          Abb.Future.return (Ok None)
      | Some (fname, content) ->
          Abbs_future_combinators.Result.map_err
            ~f:(function
              | `Json_decode_err err -> `Json_decode_err (fname, err)
              | `Unexpected_err -> `Unexpected_err fname
              | `Yaml_decode_err err -> `Yaml_decode_err (fname, err))
            (Jsonu.of_yaml_string content)
          >>= fun json -> Abb.Future.return (Ok (Some (fname, json)))

    let maybe_fetch_centralized_repo_config_file request_id client centralized_repo basename =
      match centralized_repo with
      | Some (remote_repo, branch) ->
          fetch_repo_config_file
            request_id
            client
            (Api.Remote_repo.to_repo remote_repo)
            branch
            basename
      | None -> Abb.Future.return (Ok None)

    let maybe_fetch_centralized_repo_default_branch_sha request_id client centralized_repo =
      match centralized_repo with
      | Some remote_repo -> (
          let open Abbs_future_combinators.Infix_result_monad in
          Api.fetch_branch_sha
            ~request_id
            client
            (Api.Remote_repo.to_repo remote_repo)
            (Api.Remote_repo.default_branch remote_repo)
          >>= function
          | Some branch_sha -> Abb.Future.return (Ok (Some (remote_repo, branch_sha)))
          | None -> Abb.Future.return (Ok None))
      | None -> Abb.Future.return (Ok None)

    let fetch_with_provenance ?system_defaults ?built_config request_id client repo ref_ =
      let open Abbs_future_combinators.Infix_result_monad in
      Abbs_future_combinators.Infix_result_app.(
        (fun remote_repo centralized_repo -> (remote_repo, centralized_repo))
        <$> Api.fetch_remote_repo ~request_id client repo
        <*> Api.fetch_centralized_repo ~request_id client (Api.Repo.owner repo))
      >>= fun (remote_repo, centralized_repo) ->
      Abbs_future_combinators.Infix_result_app.(
        (fun default_branch_sha centralized_repo -> (default_branch_sha, centralized_repo))
        <$> Api.fetch_branch_sha
              ~request_id
              client
              (Api.Remote_repo.to_repo remote_repo)
              (Api.Remote_repo.default_branch remote_repo)
        <*> maybe_fetch_centralized_repo_default_branch_sha request_id client centralized_repo)
      >>= fun (default_branch_sha, centralized_repo) ->
      let default_branch_ref =
        CCOption.get_or ~default:(Api.Remote_repo.default_branch remote_repo) default_branch_sha
      in
      Abbs_future_combinators.Infix_result_app.(
        (fun global_default
             global_overrides
             repo_defaults
             repo_overrides
             repo_forced_config
             default_repo_config
             repo_config
           ->
          ( global_default,
            global_overrides,
            repo_defaults,
            repo_overrides,
            repo_forced_config,
            default_repo_config,
            repo_config ))
        <$> maybe_fetch_centralized_repo_config_file
              request_id
              client
              centralized_repo
              "config/defaults"
        <*> maybe_fetch_centralized_repo_config_file
              request_id
              client
              centralized_repo
              "config/overrides"
        <*> maybe_fetch_centralized_repo_config_file
              request_id
              client
              centralized_repo
              ("config/" ^ Api.Repo.name repo ^ "/defaults")
        <*> maybe_fetch_centralized_repo_config_file
              request_id
              client
              centralized_repo
              ("config/" ^ Api.Repo.name repo ^ "/overrides")
        <*> maybe_fetch_centralized_repo_config_file
              request_id
              client
              centralized_repo
              ("config/" ^ Api.Repo.name repo ^ "/config")
        <*> fetch_repo_config_file request_id client repo default_branch_ref ".terrateam/config"
        <*> fetch_repo_config_file request_id client repo ref_ ".terrateam/config")
      >>= fun ( global_defaults,
                global_overrides,
                repo_defaults,
                repo_overrides,
                repo_forced_config,
                default_repo_config,
                repo_config )
            ->
      let wrap_err fname =
        Abbs_future_combinators.Result.map_err ~f:(function
          | `Repo_config_schema_err err -> `Repo_config_schema_err (fname, err)
          | #Terrat_base_repo_config_v1.of_version_1_err as err -> err)
      in
      let validate_configs =
        Abbs_future_combinators.List_result.iter ~f:(function
          | Some (fname, json) ->
              wrap_err fname (Abb.Future.return (Terrat_base_repo_config_v1.of_version_1_json json))
              >>= fun _ -> Abb.Future.return (Ok ())
          | None -> Abb.Future.return (Ok ()))
      in
      let get_json = function
        | None -> `Assoc []
        | Some (_, json) -> json
      in
      let get_fname = CCOption.map (fun (fname, _) -> fname) in
      let collect_provenance =
        CCList.filter_map (function
          | Some (fname, _) -> Some fname
          | None -> None)
      in
      let merge ~base v =
        CCResult.map_err
          (fun (`Type_mismatch_err err) ->
            `Config_merge_err
              ( ( CCOption.get_or ~default:"" (get_fname base),
                  CCOption.get_or ~default:"" (get_fname v) ),
                err ))
          (CCResult.map
             (fun r ->
               Some
                 ( Printf.sprintf
                     "%s,%s"
                     (CCOption.get_or ~default:"" (get_fname base))
                     (CCOption.get_or ~default:"" (get_fname v)),
                   r ))
             (Jsonu.merge ~base:(get_json base) (get_json v)))
      in
      let system_defaults =
        CCOption.map
          (fun config ->
            ( "system_defaults",
              Terrat_repo_config.Version_1.to_yojson
                (Terrat_base_repo_config_v1.to_version_1 config) ))
          system_defaults
      in
      let built_config = CCOption.map (fun config -> ("config_builder", config)) built_config in
      match
        (repo_defaults, repo_overrides, repo_forced_config, default_repo_config, repo_config)
      with
      | repo_defaults, repo_overrides, None, default_repo_config, repo_config ->
          let provenance =
            collect_provenance
              [
                system_defaults;
                global_defaults;
                global_overrides;
                repo_defaults;
                repo_overrides;
                default_repo_config;
                built_config;
                repo_config;
              ]
          in
          validate_configs
            [
              system_defaults;
              global_defaults;
              global_overrides;
              repo_defaults;
              repo_overrides;
              default_repo_config;
              built_config;
              repo_config;
            ]
          >>= fun () ->
          Abb.Future.return (merge ~base:system_defaults global_defaults)
          >>= fun global_defaults ->
          Abb.Future.return (merge ~base:global_defaults repo_defaults)
          >>= fun repo_defaults ->
          Abb.Future.return (merge ~base:repo_defaults default_repo_config)
          >>= fun default_repo_config ->
          Abb.Future.return (merge ~base:default_repo_config global_overrides)
          >>= fun default_repo_config ->
          Abb.Future.return (merge ~base:default_repo_config repo_overrides)
          >>= fun default_repo_config ->
          Abb.Future.return (merge ~base:repo_defaults built_config)
          >>= fun built_config ->
          Abb.Future.return (merge ~base:built_config repo_config)
          >>= fun repo_config ->
          Abb.Future.return (merge ~base:repo_config global_overrides)
          >>= fun repo_config ->
          Abb.Future.return (merge ~base:repo_config repo_overrides)
          >>= fun repo_config ->
          Abbs_future_combinators.Infix_result_app.(
            (fun default_repo_config repo_config -> (default_repo_config, repo_config))
            <$> wrap_err
                  "default"
                  (Abb.Future.return
                     (Terrat_base_repo_config_v1.of_version_1_json (get_json default_repo_config)))
            <*> wrap_err
                  "repo"
                  (Abb.Future.return
                     (Terrat_base_repo_config_v1.of_version_1_json (get_json repo_config))))
          >>= fun (default_repo_config, repo_config) ->
          Abb.Future.return
            (Ok
               ( provenance,
                 Terrat_base_repo_config_v1.merge_with_default_branch_config
                   ~default:default_repo_config
                   repo_config ))
      | _, _, (Some (_, _) as forced_repo_config), _, _ ->
          let provenance =
            collect_provenance [ system_defaults; global_defaults; forced_repo_config ]
          in
          validate_configs [ system_defaults; global_defaults; forced_repo_config ]
          >>= fun () ->
          Abb.Future.return (merge ~base:system_defaults global_defaults)
          >>= fun global_defaults ->
          Abb.Future.return (merge ~base:global_defaults forced_repo_config)
          >>= fun repo_config ->
          wrap_err
            "repo"
            (Abb.Future.return
               (Terrat_base_repo_config_v1.of_version_1_json (get_json repo_config)))
          >>= fun repo_config -> Abb.Future.return (Ok (provenance, repo_config))
  end

  module Access_control = struct
    let query ~request_id client repo user = match_user ~request_id client repo user

    let is_ci_changed ~request_id client repo diff =
      let run =
        let open Abbs_future_combinators.Infix_result_monad in
        Api.find_workflow_file ~request_id repo client
        >>= function
        | Some path ->
            let diff_paths =
              CCList.flat_map
                (function
                  | Terrat_change.Diff.(
                      Add { filename } | Change { filename } | Remove { filename }) -> [ filename ]
                  | Terrat_change.Diff.Move { filename; previous_filename } ->
                      [ filename; previous_filename ])
                diff
            in
            Abb.Future.return (Ok (CCList.mem ~eq:CCString.equal path diff_paths))
        | None -> Abb.Future.return (Ok false)
      in
      let open Abb.Future.Infix_monad in
      run
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error _ -> Abb.Future.return (Error `Error)
  end

  module Commit_check = struct
    let make ?work_manifest ~config ~description ~title ~status ~repo account =
      let module Wm = Terrat_work_manifest3 in
      let details_url =
        match work_manifest with
        | Some work_manifest ->
            Printf.sprintf
              "%s/i/%d/runs/%s"
              (Uri.to_string @@ Terrat_config.terrateam_web_base_url @@ Api.Config.config config)
              (Api.Account.id account)
              (Uuidm.to_string work_manifest.Wm.id)
        | None -> Uri.to_string @@ Terrat_config.terrateam_web_base_url @@ Api.Config.config config
      in
      Terrat_commit_check.make ~details_url ~description ~title ~status
  end

  module Ui = struct
    let work_manifest_url config account work_manifest =
      let module Wm = Terrat_work_manifest3 in
      Some
        (Uri.of_string
           (Printf.sprintf
              "%s/i/%d/runs/%s"
              (Uri.to_string (Terrat_config.terrateam_web_base_url @@ Api.Config.config config))
              (Api.Account.id account)
              (Uuidm.to_string work_manifest.Wm.id)))
  end

  module Comment = Terrat_vcs_service_github_provider.Comment (Ui)
end

module Routes = struct
  type config = Provider.Api.Config.t

  module Rt = struct
    let api () = Brtl_rtng.Route.(rel / "api")
    let api_v1 () = Brtl_rtng.Route.(api () / "v1")

    (* Legacy Installations API *)
    let legacy_installation_api_rt () = Brtl_rtng.Route.(api_v1 () / "installations")

    let legacy_installation_work_manifests_rt () =
      Brtl_rtng.Route.(
        legacy_installation_api_rt ()
        /% Path.int
        / "work-manifests"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(
             option
               (ud_array
                  "page"
                  Brtl_ep_paginate.Param.(of_param Typ.(tuple (string, ud' Uuidm.of_string)))))
        /? Query.(option_default 20 (Query.int "limit")))

    let legacy_installation_work_manifest_outputs_rt () =
      Brtl_rtng.Route.(
        legacy_installation_api_rt ()
        /% Path.int
        / "work-manifests"
        /% Path.ud Uuidm.of_string
        / "outputs"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.int)))
        /? Query.(option_default 20 (Query.int "limit"))
        /? Query.(option_default false (Query.bool "lite")))

    let legacy_installation_dirspaces_rt () =
      Brtl_rtng.Route.(
        legacy_installation_api_rt ()
        /% Path.int
        / "dirspaces"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(
             option
               (ud_array
                  "page"
                  Brtl_ep_paginate.Param.(
                    of_param Typ.(tuple4 (string, string, string, ud' Uuidm.of_string)))))
        /? Query.(option_default 20 (Query.int "limit")))

    let legacy_installation_pull_requests_manifests_rt () =
      Brtl_rtng.Route.(
        legacy_installation_api_rt ()
        /% Path.int
        / "pull-requests"
        /? Query.(option (int "pr"))
        /? Query.(
             option
               (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.(ud' CCInt64.of_string_opt))))
        /? Query.(option_default 20 (Query.int "limit")))

    let legacy_installation_repos_rt () =
      Brtl_rtng.Route.(
        legacy_installation_api_rt ()
        /% Path.int
        / "repos"
        /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.string)))
        /? Query.(option_default 20 (int "limit")))

    let legacy_installation_repos_refresh_rt () =
      Brtl_rtng.Route.(legacy_installation_api_rt () /% Path.int / "repos" / "refresh")

    (* VCS Specific installations API *)
    let installation_api_rt () = Brtl_rtng.Route.(api_v1 () / "github" / "installations")

    let installation_work_manifests_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "work-manifests"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(
             option
               (ud_array
                  "page"
                  Brtl_ep_paginate.Param.(of_param Typ.(tuple (string, ud' Uuidm.of_string)))))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_work_manifest_outputs_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "work-manifests"
        /% Path.ud Uuidm.of_string
        / "outputs"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.int)))
        /? Query.(option_default 20 (Query.int "limit"))
        /? Query.(option_default false (Query.bool "lite")))

    let installation_dirspaces_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "dirspaces"
        /? Query.(option (string "q"))
        /? Query.(option (string "tz"))
        /? Query.(
             option
               (ud_array
                  "page"
                  Brtl_ep_paginate.Param.(
                    of_param Typ.(tuple4 (string, string, string, ud' Uuidm.of_string)))))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_pull_requests_manifests_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "pull-requests"
        /? Query.(option (int "pr"))
        /? Query.(
             option
               (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.(ud' CCInt64.of_string_opt))))
        /? Query.(option_default 20 (Query.int "limit")))

    let installation_repos_rt () =
      Brtl_rtng.Route.(
        installation_api_rt ()
        /% Path.int
        / "repos"
        /? Query.(option (ud_array "page" Brtl_ep_paginate.Param.(of_param Typ.string)))
        /? Query.(option_default 20 (int "limit")))

    let installation_repos_refresh_rt () =
      Brtl_rtng.Route.(installation_api_rt () /% Path.int / "repos" / "refresh")

    (* User API *)
    let user_api_rt () = Brtl_rtng.Route.(api_v1 () / "user")
    let user_installations_rt () = Brtl_rtng.Route.(user_api_rt () / "github" / "installations")
  end

  let routes config storage =
    let module Ep_inst = Terrat_vcs_service_github_ee_ep_installations in
    let module Ep_user = Terrat_vcs_service_github_ee_ep_user in
    Brtl_rtng.Route.
      [
        (* Installations *)
        (`GET, Rt.installation_dirspaces_rt () --> Ep_inst.Dirspaces.get config storage);
        (`GET, Rt.installation_work_manifests_rt () --> Ep_inst.Work_manifests.get config storage);
        ( `GET,
          Rt.installation_work_manifest_outputs_rt ()
          --> Ep_inst.Work_manifests.Outputs.get config storage );
        ( `GET,
          Rt.installation_pull_requests_manifests_rt () --> Ep_inst.Pull_requests.get config storage
        );
        (`GET, Rt.installation_repos_rt () --> Ep_inst.Repos.get config storage);
        (`POST, Rt.installation_repos_refresh_rt () --> Ep_inst.Repos.Refresh.post config storage);
        (`GET, Rt.user_installations_rt () --> Ep_user.Installations.get config storage);
        (* Legacy Installations *)
        (`GET, Rt.legacy_installation_dirspaces_rt () --> Ep_inst.Dirspaces.get config storage);
        ( `GET,
          Rt.legacy_installation_work_manifests_rt () --> Ep_inst.Work_manifests.get config storage
        );
        ( `GET,
          Rt.legacy_installation_work_manifest_outputs_rt ()
          --> Ep_inst.Work_manifests.Outputs.get config storage );
        ( `GET,
          Rt.legacy_installation_pull_requests_manifests_rt ()
          --> Ep_inst.Pull_requests.get config storage );
        (`GET, Rt.legacy_installation_repos_rt () --> Ep_inst.Repos.get config storage);
        ( `POST,
          Rt.legacy_installation_repos_refresh_rt () --> Ep_inst.Repos.Refresh.post config storage
        );
      ]
end

include Terrat_vcs_service_github.Make (Provider) (Routes)

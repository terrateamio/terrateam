module Provider : Terrat_vcs_provider2_github.S = struct
  module Api = Terrat_vcs_api_github
  module Unlock_id = Terrat_vcs_service_github_provider.Unlock_id
  module Db = Terrat_vcs_service_github_provider.Db
  module Apply_requirements = Terrat_vcs_service_github_provider.Apply_requirements
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

    let repo_config_system_defaults system_defaults =
      (* Access control should be disabled for OSS *)
      let module V1 = Terrat_base_repo_config_v1 in
      let system_defaults = CCOption.get_or ~default:V1.default system_defaults in
      V1.of_view
        {
          (V1.to_view system_defaults) with
          V1.View.access_control = V1.Access_control.make ~enabled:false ();
        }

    let fetch_with_provenance ?system_defaults ?built_config request_id client repo ref_ =
      let module V1 = Terrat_base_repo_config_v1 in
      let open Abbs_future_combinators.Infix_result_monad in
      let system_defaults = repo_config_system_defaults system_defaults in
      Api.fetch_remote_repo ~request_id client repo
      >>= fun remote_repo ->
      Api.fetch_branch_sha
        ~request_id
        client
        (Api.Remote_repo.to_repo remote_repo)
        (Api.Remote_repo.default_branch remote_repo)
      >>= fun default_branch_sha ->
      let default_branch_ref =
        CCOption.get_or ~default:(Api.Remote_repo.default_branch remote_repo) default_branch_sha
      in
      Abbs_future_combinators.Infix_result_app.(
        (fun default_repo_config repo_config -> (default_repo_config, repo_config))
        <$> fetch_repo_config_file request_id client repo default_branch_ref ".terrateam/config"
        <*> fetch_repo_config_file request_id client repo ref_ ".terrateam/config")
      >>= fun (default_repo_config, repo_config) ->
      let wrap_err fname =
        Abbs_future_combinators.Result.map_err ~f:(function
          | `Repo_config_parse_err err -> `Repo_config_parse_err (fname, err)
          | #Terrat_base_repo_config_v1.of_version_1_err as err -> err)
      in
      let validate_configs =
        Abbs_future_combinators.List_result.iter ~f:(function
          | Some (fname, json) ->
              wrap_err fname (Abb.Future.return (V1.of_version_1_json json))
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
        Some
          ( "system_defaults",
            Terrat_repo_config.Version_1.to_yojson
              (Terrat_base_repo_config_v1.to_version_1 system_defaults) )
      in
      let built_config = CCOption.map (fun config -> ("config_builder", config)) built_config in
      let provenance =
        collect_provenance [ system_defaults; default_repo_config; built_config; repo_config ]
      in
      validate_configs [ system_defaults; default_repo_config; built_config; repo_config ]
      >>= fun () ->
      Abb.Future.return (merge ~base:system_defaults default_repo_config)
      >>= fun default_repo_config ->
      Abb.Future.return (merge ~base:system_defaults built_config)
      >>= fun base_repo_config ->
      Abb.Future.return (merge ~base:base_repo_config repo_config)
      >>= fun repo_config ->
      Abbs_future_combinators.Infix_result_app.(
        (fun default_repo_config repo_config -> (default_repo_config, repo_config))
        <$> wrap_err
              "default"
              (Abb.Future.return (V1.of_version_1_json (get_json default_repo_config)))
        <*> wrap_err "repo" (Abb.Future.return (V1.of_version_1_json (get_json repo_config))))
      >>= fun (default_repo_config, repo_config) ->
      let final_repo_config =
        Terrat_base_repo_config_v1.merge_with_default_branch_config
          ~default:default_repo_config
          repo_config
      in
      (* Warn OSS users about enabled functionality that only is part of the
           EE edition.  This is to make sure someone doesn't enable
           functionality and is surprised when it doesn't work. *)
      match V1.to_view final_repo_config with
      | { V1.View.access_control = { V1.Access_control.enabled = true; _ }; _ } ->
          Abb.Future.return (Error (`Premium_feature_err `Access_control))
      | { V1.View.drift = { V1.Drift.enabled = true; schedules }; _ }
        when V1.String_map.cardinal schedules > 1 ->
          Abb.Future.return (Error (`Premium_feature_err `Multiple_drift_schedules))
      | _ -> Abb.Future.return (Ok (provenance, final_repo_config))
  end

  module Access_control = struct
    (* Access control is an enterprise feature, so always return success on
         any requests. *)

    let query ~request_id _ _ _ _ = Abb.Future.return (Ok true)
    let is_ci_changed ~request_id _ _ _ = Abb.Future.return (Ok false)
  end

  module Commit_check = struct
    let make ?work_manifest ~config ~description ~title ~status ~repo account =
      let module Wm = Terrat_work_manifest3 in
      let details_url =
        match work_manifest with
        | Some { Wm.id; run_id = Some run_id; _ } ->
            Printf.sprintf
              "%s/%s/%s/actions/runs/%s"
              (Uri.to_string (Terrat_config.github_web_base_url config))
              (Api.Repo.owner repo)
              (Api.Repo.name repo)
              run_id
        | Some _ | None ->
            Printf.sprintf
              "%s/%s/%s/actions"
              (Uri.to_string (Terrat_config.github_web_base_url config))
              (Api.Repo.owner repo)
              (Api.Repo.name repo)
      in
      Terrat_commit_check.make ~details_url ~description ~title ~status
  end

  module Ui = struct
    let work_manifest_url _ _ _ = None
  end

  module Comment = Terrat_vcs_service_github_provider.Comment (Ui)
end

include
  Terrat_vcs_service_github.Make
    (Provider)
    (struct
      let routes _ _ = []
    end)

module type S = sig
  module Github : sig
    module Client : sig
      type t
    end

    module Account : sig
      type t

      val id : t -> int
    end

    module Repo : sig
      type t

      val to_string : t -> string
      val owner : t -> string
      val name : t -> string
    end

    module Ref : sig
      type t

      val to_string : t -> string
    end

    module Remote_repo : sig
      type t

      val to_repo : t -> Repo.t
      val default_branch : t -> Ref.t
    end

    val fetch_branch_sha :
      request_id:string ->
      Client.t ->
      Repo.t ->
      Ref.t ->
      (Ref.t option, [> `Error ]) result Abb.Future.t

    val fetch_remote_repo :
      request_id:string -> Client.t -> Repo.t -> (Remote_repo.t, [> `Error ]) result Abb.Future.t

    val fetch_file :
      request_id:string ->
      Client.t ->
      Repo.t ->
      Ref.t ->
      string ->
      (string option, [> `Error ]) result Abb.Future.t

    val repo_config_of_json :
      Yojson.Safe.t ->
      ( Terrat_base_repo_config_v1.raw Terrat_base_repo_config_v1.t,
        [> Terrat_base_repo_config_v1.of_version_1_err | `Repo_config_parse_err of string ] )
      result
      Abb.Future.t
  end
end

module Make (M : S) = struct
  module Github = struct
    module Client = M.Github.Client
    module Account = M.Github.Account
    module Repo = M.Github.Repo
    module Ref = M.Github.Ref
    module Remote_repo = M.Github.Remote_repo

    module Access_control = struct
      (* Access control is an enterprise feature, so always return success on
         any requests. *)

      module Ctx = struct
        type t = unit

        let make ~client ~config ~repo ~user () = ()
      end

      let query ctx match_list = Abb.Future.return (Ok true)
      let is_ci_changed ctx diff = Abb.Future.return (Ok false)
      let set_user user t = ()
    end

    module Repo_config = struct
      let fetch_repo_config_file request_id client repo ref_ basename =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_future_combinators.Infix_result_app.(
          (fun yml yaml ->
            match (yml, yaml) with
            | Some yml, _ ->
                Some (Repo.to_string repo ^ ":" ^ Ref.to_string ref_ ^ ":" ^ basename ^ ".yml", yml)
            | _, Some yaml ->
                Some
                  (Repo.to_string repo ^ ":" ^ Ref.to_string ref_ ^ ":" ^ basename ^ ".yaml", yaml)
            | _, _ -> None)
          <$> M.Github.fetch_file ~request_id client repo ref_ (basename ^ ".yml")
          <*> M.Github.fetch_file ~request_id client repo ref_ (basename ^ ".yaml"))
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

      let fetch_with_provenance ?system_defaults ?built_config request_id client repo ref_ =
        let open Abbs_future_combinators.Infix_result_monad in
        M.Github.fetch_remote_repo ~request_id client repo
        >>= fun remote_repo ->
        M.Github.fetch_branch_sha
          ~request_id
          client
          (Remote_repo.to_repo remote_repo)
          (Remote_repo.default_branch remote_repo)
        >>= fun default_branch_sha ->
        let default_branch_ref =
          CCOption.get_or ~default:(Remote_repo.default_branch remote_repo) default_branch_sha
        in
        Abbs_future_combinators.Infix_result_app.(
          (fun default_repo_config repo_config -> (default_repo_config, repo_config))
          <$> fetch_repo_config_file request_id client repo default_branch_ref ".terrateam/config"
          <*> fetch_repo_config_file request_id client repo ref_ ".terrateam/config")
        >>= fun (default_repo_config, repo_config) ->
        let wrap_err fname =
          Abbs_future_combinators.Result.map_err ~f:(function
              | ( `Access_control_ci_config_update_match_parse_err _
                | `Access_control_file_match_parse_err _
                | `Access_control_policy_apply_autoapprove_match_parse_err _
                | `Access_control_policy_apply_force_match_parse_err _
                | `Access_control_policy_apply_match_parse_err _
                | `Access_control_policy_apply_with_superapproval_match_parse_err _
                | `Access_control_policy_plan_match_parse_err _
                | `Access_control_policy_superapproval_match_parse_err _
                | `Access_control_policy_tag_query_err _
                | `Access_control_terrateam_config_update_match_parse_err _
                | `Access_control_unlock_match_parse_err _
                | `Apply_requirements_approved_all_of_match_parse_err _
                | `Apply_requirements_approved_any_of_match_parse_err _
                | `Apply_requirements_check_tag_query_err _
                | `Depends_on_err _
                | `Drift_schedule_err _
                | `Drift_tag_query_err _
                | `Glob_parse_err _
                | `Hooks_unknown_run_on_err _
                | `Pattern_parse_err _
                | `Unknown_lock_policy_err _
                | `Unknown_plan_mode_err _
                | `Workflows_apply_unknown_run_on_err _
                | `Workflows_plan_unknown_run_on_err _
                | `Workflows_tag_query_parse_err _ ) as err -> err
              | `Repo_config_parse_err err -> `Repo_config_parse_err (fname, err))
        in
        let validate_configs =
          Abbs_future_combinators.List_result.iter ~f:(function
              | Some (fname, json) ->
                  wrap_err fname (M.Github.repo_config_of_json json)
                  >>= fun _ -> Abb.Future.return (Ok ())
              | None -> Abb.Future.return (Ok ()))
        in
        let get_json = function
          | None -> `Assoc []
          | Some (_, json) -> json
        in
        let collect_provenance =
          CCList.filter_map (function
              | Some (fname, _) -> Some fname
              | None -> None)
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
        let provenance =
          collect_provenance [ system_defaults; default_repo_config; built_config; repo_config ]
        in
        validate_configs [ system_defaults; default_repo_config; built_config; repo_config ]
        >>= fun () ->
        let default_repo_config = get_json default_repo_config in
        let system_defaults = get_json system_defaults in
        let built_config = get_json built_config in
        let repo_config = get_json repo_config in
        Abb.Future.return (Jsonu.merge ~base:system_defaults built_config)
        >>= fun base_repo_config ->
        Abb.Future.return (Jsonu.merge ~base:base_repo_config repo_config)
        >>= fun repo_config ->
        Abbs_future_combinators.Infix_result_app.(
          (fun default_repo_config repo_config -> (default_repo_config, repo_config))
          <$> wrap_err "default" (M.Github.repo_config_of_json default_repo_config)
          <*> wrap_err "repo" (M.Github.repo_config_of_json repo_config))
        >>= fun (default_repo_config, repo_config) ->
        Abb.Future.return
          (Ok
             ( provenance,
               Terrat_base_repo_config_v1.merge_with_default_branch_config
                 ~default:default_repo_config
                 repo_config ))
    end

    module Commit_check = struct
      let make_commit_check ?work_manifest ~config ~description ~title ~status ~repo account =
        let module Wm = Terrat_work_manifest3 in
        let details_url =
          match work_manifest with
          | Some { Wm.id; run_id = Some run_id; _ } ->
              Printf.sprintf
                "%s/%s/%s/actions/runs/%s"
                (Uri.to_string (Terrat_config.github_web_base_url config))
                (Repo.owner repo)
                (Repo.name repo)
                run_id
          | Some _ | None ->
              Printf.sprintf
                "%s/%s/%s/actions"
                (Uri.to_string (Terrat_config.github_web_base_url config))
                (Repo.owner repo)
                (Repo.name repo)
        in
        Terrat_commit_check.make ~details_url ~description ~title ~status
    end

    module Ui = struct
      let work_manifest_url _ _ _ = None
    end
  end
end

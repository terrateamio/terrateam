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

    val fetch_centralized_repo :
      request_id:string ->
      Client.t ->
      string ->
      (Remote_repo.t option, [> `Error ]) result Abb.Future.t

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
      module Ctx = struct
        type t = {
          client : Githubc2_abb.t;
          config : Terrat_config.t;
          repo : Repo.t;
          user : string;
        }

        let make ~client ~config ~repo ~user () = { client; config; repo; user }
      end

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

      let query ctx =
        let module M = Terrat_base_repo_config_v1.Access_control.Match in
        function
        | M.User value -> Abb.Future.return (Ok (CCString.equal value ctx.Ctx.user))
        | M.Team value -> (
            let open Abb.Future.Infix_monad in
            Terrat_github.get_team_membership_in_org
              ~org:(Repo.owner ctx.Ctx.repo)
              ~team:value
              ~user:ctx.Ctx.user
              ctx.Ctx.client
            >>= function
            | Ok res -> Abb.Future.return (Ok res)
            | Error _ -> Abb.Future.return (Error `Error))
        | M.Repo value -> (
            let open Abb.Future.Infix_monad in
            match CCList.find_idx CCFun.(fst %> CCString.equal value) repo_permission_levels with
            | Some (idx, _) -> (
                Terrat_github.get_repo_collaborator_permission
                  ~org:(Repo.owner ctx.Ctx.repo)
                  ~repo:(Repo.name ctx.Ctx.repo)
                  ~user:ctx.Ctx.user
                  ctx.Ctx.client
                >>= function
                | Ok (Some role) -> (
                    match
                      CCList.find_idx CCFun.(snd %> CCString.equal role) repo_permission_levels
                    with
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

      let is_ci_changed ctx diff =
        let run =
          let open Abbs_future_combinators.Infix_result_monad in
          Terrat_github.find_workflow_file
            ~owner:(Repo.owner ctx.Ctx.repo)
            ~repo:(Repo.name ctx.Ctx.repo)
            ctx.Ctx.client
          >>= function
          | Some path ->
              let diff_paths =
                CCList.flat_map
                  (function
                    | Terrat_change.Diff.(
                        Add { filename } | Change { filename } | Remove { filename }) ->
                        [ filename ]
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

      let set_user user ctx = { ctx with Ctx.user }
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

      let maybe_fetch_centralized_repo_config_file request_id client centralized_repo basename =
        match centralized_repo with
        | Some (remote_repo, branch) ->
            fetch_repo_config_file
              request_id
              client
              (Remote_repo.to_repo remote_repo)
              branch
              basename
        | None -> Abb.Future.return (Ok None)

      let maybe_fetch_centralized_repo_default_branch_sha request_id client centralized_repo =
        match centralized_repo with
        | Some remote_repo -> (
            let open Abbs_future_combinators.Infix_result_monad in
            M.Github.fetch_branch_sha
              ~request_id
              client
              (Remote_repo.to_repo remote_repo)
              (Remote_repo.default_branch remote_repo)
            >>= function
            | Some branch_sha -> Abb.Future.return (Ok (Some (remote_repo, branch_sha)))
            | None -> Abb.Future.return (Ok None))
        | None -> Abb.Future.return (Ok None)

      let fetch_with_provenance ?system_defaults ?built_config request_id client repo ref_ =
        let open Abbs_future_combinators.Infix_result_monad in
        Abbs_future_combinators.Infix_result_app.(
          (fun remote_repo centralized_repo -> (remote_repo, centralized_repo))
          <$> M.Github.fetch_remote_repo ~request_id client repo
          <*> M.Github.fetch_centralized_repo ~request_id client (Repo.owner repo))
        >>= fun (remote_repo, centralized_repo) ->
        Abbs_future_combinators.Infix_result_app.(
          (fun default_branch_sha centralized_repo -> (default_branch_sha, centralized_repo))
          <$> M.Github.fetch_branch_sha
                ~request_id
                client
                (Remote_repo.to_repo remote_repo)
                (Remote_repo.default_branch remote_repo)
          <*> maybe_fetch_centralized_repo_default_branch_sha request_id client centralized_repo)
        >>= fun (default_branch_sha, centralized_repo) ->
        let default_branch_ref =
          CCOption.get_or ~default:(Remote_repo.default_branch remote_repo) default_branch_sha
        in
        Abbs_future_combinators.Infix_result_app.(
          (fun global_default
               global_overrides
               repo_defaults
               repo_overrides
               repo_forced_config
               default_repo_config
               repo_config ->
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
                ("config/" ^ Repo.name repo ^ "/defaults")
          <*> maybe_fetch_centralized_repo_config_file
                request_id
                client
                centralized_repo
                ("config/" ^ Repo.name repo ^ "/overrides")
          <*> maybe_fetch_centralized_repo_config_file
                request_id
                client
                centralized_repo
                ("config/" ^ Repo.name repo ^ "/config")
          <*> fetch_repo_config_file request_id client repo default_branch_ref ".terrateam/config"
          <*> fetch_repo_config_file request_id client repo ref_ ".terrateam/config")
        >>= fun ( global_defaults,
                  global_overrides,
                  repo_defaults,
                  repo_overrides,
                  repo_forced_config,
                  default_repo_config,
                  repo_config ) ->
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
            let system_defaults = get_json system_defaults in
            let global_defaults = get_json global_defaults in
            let global_overrides = get_json global_overrides in
            let repo_defaults = get_json repo_defaults in
            let repo_overrides = get_json repo_overrides in
            let default_repo_config = get_json default_repo_config in
            let built_config = get_json built_config in
            let repo_config = get_json repo_config in
            Abb.Future.return (Jsonu.merge ~base:system_defaults global_defaults)
            >>= fun global_defaults ->
            Abb.Future.return (Jsonu.merge ~base:global_defaults repo_defaults)
            >>= fun repo_defaults ->
            Abb.Future.return (Jsonu.merge ~base:repo_defaults default_repo_config)
            >>= fun default_repo_config ->
            Abb.Future.return (Jsonu.merge ~base:default_repo_config global_overrides)
            >>= fun default_repo_config ->
            Abb.Future.return (Jsonu.merge ~base:default_repo_config repo_overrides)
            >>= fun default_repo_config ->
            Abb.Future.return (Jsonu.merge ~base:repo_defaults built_config)
            >>= fun built_config ->
            Abb.Future.return (Jsonu.merge ~base:built_config repo_config)
            >>= fun repo_config ->
            Abb.Future.return (Jsonu.merge ~base:repo_config global_overrides)
            >>= fun repo_config ->
            Abb.Future.return (Jsonu.merge ~base:repo_config repo_overrides)
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
        | _, _, (Some (_, repo_forced_config) as config), _, _ ->
            let provenance = collect_provenance [ system_defaults; global_defaults; config ] in
            validate_configs [ system_defaults; global_defaults; config ]
            >>= fun () ->
            let system_defaults = get_json system_defaults in
            let global_defaults = get_json global_defaults in
            Abb.Future.return (Jsonu.merge ~base:system_defaults global_defaults)
            >>= fun global_defaults ->
            Abb.Future.return (Jsonu.merge ~base:global_defaults repo_forced_config)
            >>= fun repo_config ->
            wrap_err "repo" (M.Github.repo_config_of_json repo_config)
            >>= fun repo_config -> Abb.Future.return (Ok (provenance, repo_config))
    end

    module Commit_check = struct
      let make_commit_check ?work_manifest ~config ~description ~title ~status ~repo account =
        let module Wm = Terrat_work_manifest3 in
        let details_url =
          match work_manifest with
          | Some work_manifest ->
              Printf.sprintf
                "%s/i/%d/audit-trail/%s"
                (Uri.to_string (Terrat_config.terrateam_web_base_url config))
                (Account.id account)
                (Uuidm.to_string work_manifest.Wm.id)
          | None -> Uri.to_string (Terrat_config.terrateam_web_base_url config)
        in
        Terrat_commit_check.make ~details_url ~description ~title ~status
    end
  end
end

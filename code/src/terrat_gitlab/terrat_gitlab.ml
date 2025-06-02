let src = Logs.Src.create "terrat_gitlab"

module Logs = (val Logs.src_log src : Logs.LOG)

let one_minute = Duration.(to_f (of_min 1))
let terrateam_workflow_name = "Terrateam Workflow"
let terrateam_workflow_path = ".gitlab/workflows/terrateam.yml"
let installation_expiration_sec = one_minute
let call_timeout = Duration.(to_f (of_sec 10))

module Metrics = struct
  module Call_retry_wait_histograph = Prmths.Histogram (struct
    let spec = Prmths.Histogram_spec.of_exponential ~start:30.0 ~factor:1.2 ~count:20
  end)

  module Rate_limit_remaining_histograph = Prmths.Histogram (struct
    let spec =
      Prmths.Histogram_spec.of_list
        [ 100.0; 500.0; 1000.0; 2000.0; 3000.0; 4000.0; 5000.0; 6000.0; 10000.0 ]
  end)

  let namespace = "terrat"
  let subsystem = "gitlab"

  let call_retries_total =
    let help = "Number of retries in a call" in
    Prmths.Counter.v ~help ~namespace ~subsystem "call_retries_total"

  let rate_limit_retry_wait_seconds =
    let help = "Number of seconds a call has spent waiting due to rate limit" in
    Call_retry_wait_histograph.v ~help ~namespace ~subsystem "rate_limit_retry_wait_seconds"

  let rate_limit_remaining_count =
    let help = "Number of calls remaining in the rate limit window." in
    Rate_limit_remaining_histograph.v ~help ~namespace ~subsystem "rate_limit_remaining_count"

  let fn_call_total =
    let help = "Number of calls of a function" in
    Prmths.Counter.v_label ~label_name:"fn" ~help ~namespace ~subsystem "fn_call_total"
end

type user_err =
  [ Openapic_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_modified
  | `Unauthorized of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

type get_installation_access_token_err =
  [ Openapic_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_user_installations_err =
  [ Openapic_abb.call_err
  | `Unauthorized of Githubc2_components.Basic_error.t
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_modified
  ]
[@@deriving show]

type get_installation_repos_err =
  [ Openapic_abb.call_err
  | `Not_modified
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unauthorized of Githubc2_components.Basic_error.t
  ]
[@@deriving show]

type fetch_file_err =
  [ Openapic_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Found
  | `Not_file
  | `Not_modified
  ]
[@@deriving show]

type fetch_pull_request_err =
  [ Openapic_abb.call_err
  | `Not_modified
  | `Not_found of Githubc2_components.Basic_error.t
  | `Not_acceptable of Githubc2_components.Basic_error.t
  | `Internal_server_error of Githubc2_components.Basic_error.t
  | `Service_unavailable of Githubc2_pulls.Get.Responses.Service_unavailable.t
  ]
[@@deriving show]

type fetch_repo_err =
  [ Openapic_abb.call_err
  | `Moved_permanently of Githubc2_repos.Get.Responses.Moved_permanently.t
  | `Forbidden of Githubc2_repos.Get.Responses.Forbidden.t
  | `Not_found of Githubc2_repos.Get.Responses.Not_found.t
  ]
[@@deriving show]

type fetch_branch_err =
  [ Openapic_abb.call_err
  | `Moved_permanently of Githubc2_repos.Get_branch.Responses.Moved_permanently.t
  | `Not_found of Githubc2_repos.Get_branch.Responses.Not_found.t
  ]
[@@deriving show]

type publish_comment_err =
  [ Openapic_abb.call_err
  | `Forbidden of Githubc2_components.Basic_error.t
  | `Not_found of Githubc2_components.Basic_error.t
  | `Gone of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type publish_reaction_err =
  [ Openapic_abb.call_err
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  ]
[@@deriving show]

type get_tree_err =
  [ Openapic_abb.call_err
  | `Not_found of Githubc2_components.Basic_error.t
  | `Unprocessable_entity of Githubc2_components.Validation_error.t
  | `Conflict of Githubc2_components.Basic_error.t
  | `Error
  ]
[@@deriving show]

type get_team_membership_in_org_err = Openapic_abb.call_err [@@deriving show]
type get_repo_collaborator_permission_err = Openapic_abb.call_err [@@deriving show]

let project_id owner name = Uri.pct_encode @@ owner ^ "/" ^ name

let not_found =
  `Not_found
    Githubc2_components_basic_error.(
      make
        { Primary.documentation_url = None; message = Some "Not_found"; status = None; url = None })

module Commit_status = struct
  type create_err = Openapic_abb.call_err [@@deriving show]

  type list_err =
    [ Openapic_abb.call_err
    | `Error
    | `Moved_permanently of Githubc2_components.Basic_error.t
    ]
  [@@deriving show]

  module Create = struct
    module T = struct
      type t = unit [@@deriving show]

      let make ?target_url ?description ?context ~state () =
        (* TODO: Implement *)
        ()
    end

    type t = T.t list
  end

  let create ~owner ~repo ~sha ~creates client =
    (* TODO: Implement *)
    Abb.Future.return (Ok ())

  let list ~owner ~repo ~sha client =
    (* TODO: Implement *)
    Abb.Future.return (Ok [])
end

module Status_check = struct
  type list_err = Openapic_abb.call_err [@@deriving show]

  let list ~owner ~repo ~ref_ client =
    (* TODO: Implement *)
    Abb.Future.return (Ok [])
end

module Pull_request_reviews = struct
  type list_err =
    [ `Error
    | Openapic_abb.call_err
    ]
  [@@deriving show]

  let list ~owner ~repo ~pull_number client =
    (* TODO: Implement *)
    Abb.Future.return (Ok [])
end

let create config auth =
  Openapic_abb.create
    ~base_url:(Terrat_config.Gitlab.api_base_url config)
    ~user_agent:"Terrateam"
    ~call_timeout
    auth

let with_client config auth f =
  let client = create config auth in
  f client

let call ?tries client re = raise (Failure "nyi")
let user ~config ~access_token () = raise (Failure "nyi")

let get_installation_access_token
    ?(expiration_sec = installation_expiration_sec)
    ?permissions
    config
    installation_id =
  raise (Failure "nyi")

let fetch_repo ~owner ~repo client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_repo");
  let module Gl = Gitlabc_projects.GetApiV4ProjectsId in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  call client Gl.(make (Parameters.make ~id ()))
  >>= fun resp ->
  let module R = Gitlabc_components.API_Entities_ProjectWithAccess in
  match Openapi.Response.value resp with
  | `OK
      {
        R.links_;
        allow_merge_on_skipped_pipeline;
        allow_pipeline_trigger_approve_deployment;
        analytics_access_level;
        approvals_before_merge;
        archived;
        auto_cancel_pending_pipelines;
        auto_devops_deploy_strategy;
        auto_devops_enabled;
        autoclose_referenced_issues;
        avatar_url;
        build_git_strategy;
        build_timeout;
        builds_access_level;
        can_create_merge_request_in;
        ci_allow_fork_pipelines_to_run_in_parent_project;
        ci_config_path;
        ci_default_git_depth;
        ci_delete_pipelines_in_seconds;
        ci_forward_deployment_enabled;
        ci_forward_deployment_rollback_allowed;
        ci_id_token_sub_claim_components;
        ci_job_token_scope_enabled;
        ci_pipeline_variables_minimum_override_role;
        ci_push_repository_for_job_token_allowed;
        ci_restrict_pipeline_cancellation_role;
        ci_separated_caches;
        compliance_frameworks;
        container_expiration_policy;
        container_registry_access_level;
        container_registry_enabled;
        container_registry_image_prefix;
        created_at;
        creator_id;
        custom_attributes;
        default_branch;
        description;
        description_html;
        emails_disabled;
        emails_enabled;
        empty_repo;
        enforce_auth_checks_on_uploads;
        environments_access_level;
        external_authorization_classification_label;
        feature_flags_access_level;
        forked_from_project;
        forking_access_level;
        forks_count;
        group_runners_enabled;
        http_url_to_repo;
        id;
        import_error;
        import_status;
        import_type;
        import_url;
        infrastructure_access_level;
        issue_branch_template;
        issues_access_level;
        issues_enabled;
        issues_template;
        jobs_enabled;
        keep_latest_artifact;
        last_activity_at;
        lfs_enabled;
        license;
        license_url;
        marked_for_deletion_at;
        marked_for_deletion_on;
        max_artifacts_size;
        merge_commit_template;
        merge_method;
        merge_pipelines_enabled;
        merge_requests_access_level;
        merge_requests_enabled;
        merge_requests_template;
        merge_trains_enabled;
        merge_trains_skip_train_allowed;
        mirror;
        mirror_overwrites_diverged_branches;
        mirror_trigger_builds;
        mirror_user_id;
        model_experiments_access_level;
        model_registry_access_level;
        monitor_access_level;
        mr_default_target_self;
        name;
        name_with_namespace;
        namespace;
        only_allow_merge_if_all_discussions_are_resolved;
        only_allow_merge_if_all_status_checks_passed;
        only_allow_merge_if_pipeline_succeeds;
        only_mirror_protected_branches;
        open_issues_count;
        owner = owner_;
        packages_enabled;
        pages_access_level;
        path;
        path_with_namespace;
        permissions;
        pre_receive_secret_detection_enabled;
        prevent_merge_without_jira_issue;
        printing_merge_request_link_enabled;
        public_jobs;
        readme_url;
        releases_access_level;
        remove_source_branch_after_merge;
        repository_access_level;
        repository_object_format;
        repository_storage;
        request_access_enabled;
        requirements_access_level;
        requirements_enabled;
        resolve_outdated_diff_discussions;
        restrict_user_defined_variables;
        runner_token_expiration_interval;
        runners_token;
        secret_push_protection_enabled;
        security_and_compliance_access_level;
        security_and_compliance_enabled;
        service_desk_address;
        service_desk_enabled;
        shared_runners_enabled;
        shared_with_groups;
        snippets_access_level;
        snippets_enabled;
        squash_commit_template;
        squash_option;
        ssh_url_to_repo;
        star_count;
        statistics;
        suggestion_commit_message;
        tag_list;
        topics;
        updated_at;
        visibility;
        warn_about_potentially_unwanted_characters;
        web_url;
        wiki_access_level;
        wiki_enabled;
      } ->
      let module Gh = Githubc2_components.Full_repository in
      Abb.Future.return
        (Ok
           (Gh.make
              {
                Gh.Primary.allow_auto_merge = None;
                allow_forking = None;
                allow_merge_commit = None;
                allow_rebase_merge = None;
                allow_squash_merge = None;
                allow_update_branch = None;
                anonymous_access_enabled = true;
                archive_url = "";
                archived = CCOption.get_or ~default:false archived;
                assignees_url = "";
                blobs_url = "";
                branches_url = "";
                clone_url = "";
                code_of_conduct = None;
                collaborators_url = "";
                comments_url = "";
                commits_url = "";
                compare_url = "";
                contents_url = "";
                contributors_url = "";
                created_at = CCOption.get_or ~default:"" created_at;
                custom_properties = None;
                default_branch = CCOption.get_exn_or "default_branch" default_branch;
                delete_branch_on_merge = None;
                deployments_url = "";
                description;
                disabled = false;
                downloads_url = "";
                events_url = "";
                fork = CCOption.is_some forked_from_project;
                forks = CCOption.get_or ~default:0 forks_count;
                forks_count = CCOption.get_or ~default:0 forks_count;
                forks_url = "";
                full_name = "fake";
                git_commits_url = "fake_url";
                git_refs_url = "fake_url";
                git_tags_url = "fake_url";
                git_url = "fake_url";
                has_discussions = false;
                has_downloads = None;
                has_issues = false;
                has_pages = false;
                has_projects = false;
                has_wiki = false;
                homepage = None;
                hooks_url = "fake_url";
                html_url = "fake_url";
                id = CCInt64.of_int @@ CCOption.get_exn_or "id" id;
                is_template = None;
                issue_comment_url = "fake_url";
                issue_events_url = "fake_url";
                issues_url = "fake_url";
                keys_url = "fake_url";
                labels_url = "fake_url";
                language = None;
                languages_url = "fake_url";
                license = None;
                master_branch = default_branch;
                merge_commit_message = None;
                merge_commit_title = None;
                merges_url = "fake_url";
                milestones_url = "fake_url";
                mirror_url = None;
                name = repo;
                network_count = 0;
                node_id = project_id owner repo;
                notifications_url = "fake_url";
                open_issues = 0;
                open_issues_count = 0;
                organization = None;
                owner =
                  Githubc2_components.Simple_user.(
                    make
                      {
                        Primary.avatar_url = "fake_url";
                        email = None;
                        events_url = "fake_url";
                        followers_url = "fake_url";
                        following_url = "fake_url";
                        gists_url = "fake_url";
                        gravatar_id = None;
                        html_url = "fake_url";
                        id =
                          (let module U = Gitlabc_components_api_entities_userbasic in
                          CCInt64.of_int @@ (CCOption.get_exn_or "owner_" owner_).U.id);
                        login = owner;
                        name = None;
                        node_id = owner;
                        organizations_url = "fake_url";
                        received_events_url = "fake_url";
                        repos_url = "fake_url";
                        site_admin = false;
                        starred_at = None;
                        starred_url = "fake_url";
                        subscriptions_url = "fake_url";
                        type_ = "fake_type";
                        url = "fake_url";
                        user_view_type = None;
                      });
                parent = None;
                permissions = None;
                private_ = true;
                pulls_url = "fake_url";
                pushed_at = "";
                releases_url = "fake_url";
                security_and_analysis = None;
                size = -1;
                source = None;
                squash_merge_commit_message = None;
                squash_merge_commit_title = None;
                ssh_url = "fake_url";
                stargazers_count = 0;
                stargazers_url = "fake_url";
                statuses_url = "fake_url";
                subscribers_count = 0;
                subscribers_url = "fake_url";
                subscription_url = "fake_url";
                svn_url = "fake_url";
                tags_url = "fake_url";
                teams_url = "fake_url";
                temp_clone_token = None;
                template_repository = None;
                topics = None;
                trees_url = "fake_url";
                updated_at = CCOption.get_or ~default:"" updated_at;
                url = "fake_url";
                use_squash_pr_title_as_default = None;
                visibility = None;
                watchers = 0;
                watchers_count = 0;
                web_commit_signoff_required = None;
              }))
  | `Not_found -> Abb.Future.return (Error not_found)

let repo_of_full_repo full_repo =
  let module Gh = Githubc2_components.Full_repository in
  let {
    Gh.primary =
      {
        Gh.Primary.allow_auto_merge;
        allow_forking;
        allow_merge_commit;
        allow_rebase_merge;
        allow_squash_merge;
        allow_update_branch;
        anonymous_access_enabled;
        archive_url;
        archived;
        assignees_url;
        blobs_url;
        branches_url;
        clone_url;
        code_of_conduct;
        collaborators_url;
        comments_url;
        commits_url;
        compare_url;
        contents_url;
        contributors_url;
        created_at;
        custom_properties;
        default_branch;
        delete_branch_on_merge;
        deployments_url;
        description;
        disabled;
        downloads_url;
        events_url;
        fork;
        forks;
        forks_count;
        forks_url;
        full_name;
        git_commits_url;
        git_refs_url;
        git_tags_url;
        git_url;
        has_discussions;
        has_downloads;
        has_issues;
        has_pages;
        has_projects;
        has_wiki;
        homepage;
        hooks_url;
        html_url;
        id;
        is_template;
        issue_comment_url;
        issue_events_url;
        issues_url;
        keys_url;
        labels_url;
        language;
        languages_url;
        license;
        master_branch;
        merge_commit_message;
        merge_commit_title;
        merges_url;
        milestones_url;
        mirror_url;
        name;
        network_count;
        node_id;
        notifications_url;
        open_issues;
        open_issues_count;
        organization;
        owner;
        parent;
        permissions;
        private_;
        pulls_url;
        pushed_at;
        releases_url;
        security_and_analysis;
        size;
        source;
        squash_merge_commit_message;
        squash_merge_commit_title;
        ssh_url;
        stargazers_count;
        stargazers_url;
        statuses_url;
        subscribers_count;
        subscribers_url;
        subscription_url;
        svn_url;
        tags_url;
        teams_url;
        temp_clone_token;
        template_repository;
        topics;
        trees_url;
        updated_at;
        url;
        use_squash_pr_title_as_default;
        visibility;
        watchers;
        watchers_count;
        web_commit_signoff_required;
      };
    _;
  } =
    full_repo
  in
  let module Ghfr = Githubc2_components.Full_repository in
  let module Gh = Githubc2_components.Repository in
  Gh.(
    make
      {
        Primary.allow_auto_merge = CCOption.get_or ~default:false allow_auto_merge;
        allow_forking;
        allow_merge_commit = CCOption.get_or ~default:true allow_merge_commit;
        allow_rebase_merge = CCOption.get_or ~default:true allow_rebase_merge;
        allow_squash_merge = CCOption.get_or ~default:true allow_squash_merge;
        allow_update_branch = CCOption.get_or ~default:true allow_update_branch;
        anonymous_access_enabled = Some anonymous_access_enabled;
        archive_url;
        archived;
        assignees_url;
        blobs_url;
        branches_url;
        clone_url;
        collaborators_url;
        comments_url;
        commits_url;
        compare_url;
        contents_url;
        contributors_url;
        created_at = Some created_at;
        default_branch;
        delete_branch_on_merge = CCOption.get_or ~default:false delete_branch_on_merge;
        deployments_url;
        description;
        disabled;
        downloads_url;
        events_url;
        fork;
        forks;
        forks_count;
        forks_url;
        full_name;
        git_commits_url;
        git_refs_url;
        git_tags_url;
        git_url;
        has_discussions;
        has_downloads = CCOption.get_or ~default:true has_downloads;
        has_issues;
        has_pages;
        has_projects;
        has_wiki;
        homepage;
        hooks_url;
        html_url;
        id;
        is_template = CCOption.get_or ~default:false is_template;
        issue_comment_url;
        issue_events_url;
        issues_url;
        keys_url;
        labels_url;
        language;
        languages_url;
        license;
        master_branch;
        merge_commit_message;
        merge_commit_title;
        merges_url;
        milestones_url;
        mirror_url;
        name;
        node_id;
        notifications_url;
        open_issues;
        open_issues_count;
        owner;
        permissions =
          CCOption.map
            (fun {
                   Ghfr.Primary.Permissions.primary =
                     { Ghfr.Primary.Permissions.Primary.admin; maintain; pull; push; triage };
                   _;
                 }
               -> Gh.Primary.Permissions.(make { Primary.admin; maintain; pull; push; triage }))
            permissions;
        private_;
        pulls_url;
        pushed_at = Some pushed_at;
        releases_url;
        size;
        squash_merge_commit_message;
        squash_merge_commit_title;
        ssh_url;
        stargazers_count;
        stargazers_url;
        starred_at = None;
        statuses_url;
        subscribers_url;
        subscription_url;
        svn_url;
        tags_url;
        teams_url;
        temp_clone_token;
        topics;
        trees_url;
        updated_at = Some updated_at;
        url;
        use_squash_pr_title_as_default =
          CCOption.get_or ~default:false use_squash_pr_title_as_default;
        visibility = CCOption.get_or ~default:"public" visibility;
        watchers;
        watchers_count;
        web_commit_signoff_required = CCOption.get_or ~default:false web_commit_signoff_required;
      })

let fetch_branch ~owner ~repo ~branch client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_branch");
  let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryBranchesBranch in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  call client Gl.(make (Parameters.make ~branch ~id))
  >>= fun resp ->
  let module R = Gitlabc_components_api_entities_branch in
  let module Glc = Gitlabc_components_api_entities_commit in
  match Openapi.Response.value resp with
  | `OK
      {
        R.can_push;
        commit =
          {
            Glc.author_email;
            author_name;
            authored_date;
            committed_date;
            committer_email;
            committer_name;
            created_at;
            extended_trailers;
            id;
            message;
            parent_ids;
            short_id;
            title;
            trailers;
            web_url = _;
          };
        default;
        developers_can_merge;
        developers_can_push;
        merged;
        name;
        protected;
        web_url = _;
      } ->
      let module Gh = Githubc2_components_branch_with_protection in
      let module Ghc = Githubc2_components_commit in
      let module Ghp = Githubc2_components_branch_protection in
      Abb.Future.return
        (Ok
           Gh.(
             make
               {
                 Primary.links_ =
                   Primary.Links_.(make { Primary.html = "fake_url"; self = "fake_url" });
                 commit =
                   Ghc.(
                     make
                       {
                         Primary.author = None;
                         comments_url = "fake_url";
                         commit =
                           Primary.Commit_.(
                             make
                               {
                                 Primary.author = None;
                                 comment_count = 0;
                                 committer = None;
                                 message = CCOption.get_or ~default:"" message;
                                 tree =
                                   Primary.Tree.(
                                     make { Primary.sha = "fake_sha"; url = "fake_url" });
                                 url = "fake_url";
                                 verification = None;
                               });
                         committer = None;
                         files = None;
                         html_url = "fake_url";
                         node_id = id;
                         parents = [];
                         sha = id;
                         stats = None;
                         url = "fake_url";
                       });
                 name;
                 pattern = None;
                 protected = false;
                 protection =
                   Ghp.(
                     make
                       {
                         Primary.allow_deletions = None;
                         allow_force_pushes = None;
                         allow_fork_syncing = None;
                         block_creations = None;
                         enabled = None;
                         enforce_admins = None;
                         lock_branch = None;
                         name = None;
                         protection_url = None;
                         required_conversation_resolution = None;
                         required_linear_history = None;
                         required_pull_request_reviews = None;
                         required_signatures = None;
                         required_status_checks = None;
                         restrictions = None;
                         url = None;
                       });
                 protection_url = "fake_url";
                 required_approving_review_count = None;
               }))
  | `Not_found -> Abb.Future.return (Error not_found)

let fetch_file ~owner ~repo ~ref_ ~path client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_file");
  let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryFilesFilePath in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  call client Gl.(make (Parameters.make ~file_path:path ~ref_ ~id))
  >>= fun resp ->
  let module R = Gl.Responses.OK in
  match Openapi.Response.value resp with
  | `OK
      {
        R.blob_id;
        commit_id;
        content;
        content_sha256;
        encoding;
        execute_filemode;
        file_name;
        file_path;
        last_commit_id;
        ref_;
        size;
      } ->
      let module Gh = Githubc2_components.Content_file in
      Abb.Future.return
        (Ok
           (Some
              (Gh.make
                 {
                   Gh.Primary.links_ =
                     Gh.Primary.Links_.(make @@ { Primary.git = None; html = None; self = "" });
                   content;
                   download_url = None;
                   encoding;
                   git_url = None;
                   html_url = None;
                   name = file_name;
                   path = file_path;
                   sha = ref_;
                   size;
                   submodule_git_url = None;
                   target = None;
                   type_ = "file";
                   url = "";
                 })))
  | `Not_found -> Abb.Future.return (Ok None)

let fetch_pull_request_files ~owner ~repo ~pull_number client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_pull_request_files");
  let module Gl =
    Gitlabc_projects_merge_requests.GetApiV4ProjectsIdMergeRequestsMergeRequestIidDiffs
  in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  Openapic_abb.collect_all
    ~page:Openapic_abb.Page.gitlab
    client
    Gl.(make (Parameters.make ~id ~merge_request_iid:pull_number ()))
  >>= fun diff ->
  let module Gld = Gitlabc_components_api_entities_diff in
  Abb.Future.return
    (Ok
       (CCList.map
          (fun {
                 Gld.a_mode;
                 b_mode;
                 deleted_file;
                 diff;
                 generated_file;
                 new_file;
                 new_path;
                 old_path;
                 renamed_file;
               }
             ->
            let module Ghd = Githubc2_components_diff_entry in
            Ghd.(
              make
                {
                  Primary.additions = 0;
                  blob_url = "fake_url";
                  changes = 0;
                  contents_url = "fake_url";
                  deletions = 0;
                  filename = new_path;
                  patch = Some diff;
                  previous_filename =
                    (if not (CCString.equal old_path new_path) then Some old_path else None);
                  raw_url = "fake_url";
                  sha = "fake_sha";
                  status =
                    (if new_file then "added"
                     else if renamed_file then "renamed"
                     else if deleted_file then "removed"
                     else "changed");
                }))
          diff))

let fetch_pull_request ~owner ~repo ~pull_number client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "fetch_pull_request");
  let module Gl = Gitlabc_projects_merge_requests.GetApiV4ProjectsIdMergeRequestsMergeRequestIid in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  call client Gl.(make (Parameters.make ~id ~merge_request_iid:pull_number ()))
  >>= fun resp ->
  fetch_repo ~owner ~repo client
  >>= fun repo ->
  let module Mr = Gitlabc_components_api_entities_mergerequest in
  match Openapi.Response.value resp with
  | `OK
      {
        Mr.allow_collaboration;
        allow_maintainer_to_push;
        approvals_before_merge;
        assignee;
        assignees;
        author;
        blocking_discussions_resolved;
        changes_count;
        closed_at;
        closed_by;
        created_at;
        description;
        description_html;
        detailed_merge_status;
        diff_refs;
        discussion_locked;
        diverged_commits_count;
        downvotes;
        draft;
        first_contribution;
        first_deployed_to_production_at;
        force_remove_source_branch;
        has_conflicts;
        head_pipeline;
        id;
        iid;
        imported;
        imported_from;
        labels;
        latest_build_finished_at;
        latest_build_started_at;
        merge_after;
        merge_commit_sha;
        merge_error;
        merge_status;
        merge_user;
        merge_when_pipeline_succeeds;
        merged_at;
        merged_by;
        milestone;
        pipeline;
        prepared_at;
        project_id;
        rebase_in_progress;
        reference;
        references;
        reviewers;
        sha;
        should_remove_source_branch;
        source_branch;
        source_project_id;
        squash;
        squash_commit_sha;
        squash_on_merge;
        state;
        subscribed;
        target_branch;
        target_project_id;
        task_completion_status;
        time_stats;
        title;
        title_html;
        updated_at;
        upvotes;
        user;
        user_notes_count;
        web_url;
        work_in_progress;
      } ->
      let module Gh = Githubc2_components_pull_request in
      let link = Githubc2_components_link.(make { Primary.href = "fake_url" }) in
      Abb.Future.return
        (Ok
           Gh.(
             make
               {
                 Primary.links_ =
                   Primary.Links_.(
                     make
                       {
                         Primary.comments = link;
                         commits = link;
                         html = link;
                         issue = link;
                         review_comment = link;
                         review_comments = link;
                         self = link;
                         statuses = link;
                       });
                 active_lock_reason = None;
                 additions = 0;
                 assignee = None;
                 assignees = None;
                 author_association = "MANNEQUIN";
                 auto_merge = None;
                 base =
                   Primary.Base.(
                     make
                       {
                         Primary.label = "fake_label";
                         ref_ = "fake_ref";
                         repo = repo_of_full_repo repo;
                         sha = "fake_sha";
                         user =
                           (let module U = Githubc2_components_simple_user in
                           U.(
                             make
                               {
                                 Primary.avatar_url = "fake_url";
                                 email = None;
                                 events_url = "fake_url";
                                 followers_url = "fake_url";
                                 following_url = "fake_url";
                                 gists_url = "fake_url";
                                 gravatar_id = None;
                                 html_url = "fake_url";
                                 id = -1L;
                                 login = "fake_login";
                                 name = None;
                                 node_id = "fake_node_id";
                                 organizations_url = "fake_url";
                                 received_events_url = "fake_url";
                                 repos_url = "fake_url";
                                 site_admin = false;
                                 starred_at = None;
                                 starred_url = "fake_url";
                                 subscriptions_url = "fake_url";
                                 type_ = "fake_type_";
                                 url = "fake_url";
                                 user_view_type = None;
                               }));
                       });
                 body = description;
                 changed_files = 0;
                 closed_at;
                 comments = 0;
                 comments_url = "fake_url";
                 commits = 0;
                 commits_url = "fake_url";
                 created_at;
                 deletions = 0;
                 diff_url = "fake_url";
                 draft;
                 head =
                   Primary.Head.(
                     make
                       {
                         Primary.label = "fake_label";
                         ref_ = "fake_ref";
                         repo = repo_of_full_repo repo;
                         sha = "fake_sha";
                         user =
                           (let module U = Githubc2_components_simple_user in
                           U.(
                             make
                               {
                                 Primary.avatar_url = "fake_url";
                                 email = None;
                                 events_url = "fake_url";
                                 followers_url = "fake_url";
                                 following_url = "fake_url";
                                 gists_url = "fake_url";
                                 gravatar_id = None;
                                 html_url = "fake_url";
                                 id = -1L;
                                 login = "fake_login";
                                 name = None;
                                 node_id = "fake_node_id";
                                 organizations_url = "fake_url";
                                 received_events_url = "fake_url";
                                 repos_url = "fake_url";
                                 site_admin = false;
                                 starred_at = None;
                                 starred_url = "fake_url";
                                 subscriptions_url = "fake_url";
                                 type_ = "fake_type_";
                                 url = "fake_url";
                                 user_view_type = None;
                               }));
                       });
                 html_url = "fake_url";
                 id = CCInt64.of_int id;
                 issue_url = "fake_url";
                 labels = [];
                 locked = false;
                 maintainer_can_modify = true;
                 merge_commit_sha;
                 mergeable = CCOption.map (( = ) "can_be_merged") merge_status;
                 mergeable_state =
                   (match merge_status with
                   | Some ("can_be_merged" | "mergeable") -> "clean"
                   | _ -> "blocked");
                 merged = CCOption.is_some merged_at;
                 merged_at;
                 merged_by =
                   (let module Glu = Gitlabc_components_api_entities_userbasic in
                   CCOption.map
                     (fun
                       {
                         Glu.avatar_path;
                         avatar_url;
                         custom_attributes;
                         id;
                         locked;
                         name;
                         state;
                         username;
                         web_url;
                       }
                     ->
                       let module Ghu = Githubc2_components_nullable_simple_user in
                       Ghu.(
                         make
                           {
                             Primary.avatar_url = CCOption.get_or ~default:"fake_url" avatar_url;
                             email = None;
                             events_url = "fake_url";
                             followers_url = "fake_url";
                             following_url = "fake_url";
                             gists_url = "fake_url";
                             gravatar_id = None;
                             html_url = "fake_url";
                             id = CCInt64.of_int id;
                             login = username;
                             name = None;
                             node_id = CCInt.to_string id;
                             organizations_url = "fake_url";
                             received_events_url = "fake_url";
                             repos_url = "fake_url";
                             site_admin = false;
                             starred_at = None;
                             starred_url = "fake_url";
                             subscriptions_url = "fake_url";
                             type_ = "fake_type";
                             url = "fake_url";
                             user_view_type = None;
                           })))
                     merged_by;
                 milestone = None;
                 node_id = CCInt.to_string iid;
                 number = id;
                 patch_url = "fake_url";
                 rebaseable = None;
                 requested_reviewers = None;
                 requested_teams = None;
                 review_comment_url = "fake_url";
                 review_comments = 0;
                 review_comments_url = "fake_url";
                 state;
                 statuses_url = "fake_url";
                 title;
                 updated_at = CCOption.get_or ~default:"" updated_at;
                 url = "fake_user";
                 user =
                   (let module U = Githubc2_components_simple_user in
                   U.(
                     make
                       {
                         Primary.avatar_url = "fake_url";
                         email = None;
                         events_url = "fake_url";
                         followers_url = "fake_url";
                         following_url = "fake_url";
                         gists_url = "fake_url";
                         gravatar_id = None;
                         html_url = "fake_url";
                         id = -1L;
                         login = "fake_login";
                         name = None;
                         node_id = "fake_node_id";
                         organizations_url = "fake_url";
                         received_events_url = "fake_url";
                         repos_url = "fake_url";
                         site_admin = false;
                         starred_at = None;
                         starred_url = "fake_url";
                         subscriptions_url = "fake_url";
                         type_ = "fake_type_";
                         url = "fake_url";
                         user_view_type = None;
                       }));
               }))
  | `Not_found -> Abb.Future.return (Error not_found)

let get_user_installations client = raise (Failure "nyi")
let get_installation_repos client = raise (Failure "nyi")
let find_workflow_file ~owner ~repo client = raise (Failure "nyi")
let load_workflow ~owner ~repo client = raise (Failure "nyi")

let publish_comment ~owner ~repo ~pull_number ~body client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "publish_comment");
  let module Gl =
    Gitlabc_projects_merge_requests.PostApiV4ProjectsIdMergeRequestsMergeRequestIidNotesNotesId
  in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  call client Gl.(make (Parameters.make ~id ~merge_request_iid:pull_number ~body))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK -> Abb.Future.return (Ok ())
  | `Not_found -> Abb.Future.return (Error not_found)

let react_to_comment ?(content = "rocket") ~owner ~repo ~comment_id client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "react_to_comment");
  Abb.Future.return (Ok ())

let get_tree ~owner ~repo ~sha client =
  Prmths.Counter.inc_one (Metrics.fn_call_total "get_tree");
  let module Gl = Gitlabc_projects_repository.GetApiV4ProjectsIdRepositoryTree in
  let open Abbs_future_combinators.Infix_result_monad in
  let id = project_id owner repo in
  Openapic_abb.collect_all
    ~page:Openapic_abb.Page.gitlab
    client
    Gl.(make (Parameters.make ~ref_:(Some sha) ~id ~recursive:true ()))
  >>= fun tree ->
  let module T = Gitlabc_components.API_Entities_TreeObject in
  Abb.Future.return
    (Ok
       (CCList.filter_map
          (function
            | { T.path; type_ = "blob"; _ } -> Some path
            | _ -> None)
          tree))

let get_team_membership_in_org ~org ~team ~user client = raise (Failure "nyi")
let get_repo_collaborator_permission ~org ~repo ~user client = raise (Failure "nyi")

module Oauth = struct
  module Http = Abb_curl.Make (Abb)

  type authorize_err =
    [ `Authorize_err of string
    | Http.request_err
    ]
  [@@deriving show]

  type refresh_err =
    [ `Refresh_err of string
    | `Bad_refresh_token
    | Http.request_err
    ]
  [@@deriving show]

  module Response = struct
    type t = {
      access_token : string;
      scope : string;
      token_type : string;
      refresh_token : string option; [@default None]
      refresh_token_expires_in : int option; [@default None]
      expires_in : int option; [@default None]
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  module Response_err = struct
    type t = {
      error : string;
      error_description : string;
    }
    [@@deriving of_yojson { strict = false }, show]
  end

  let authorize ~config code =
    let open Abb.Future.Infix_monad in
    let headers =
      Http.Headers.of_list [ ("user-agent", "Terrateam"); ("content-type", "application/json") ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf
           "%s/oauth/authorize"
           (Uri.to_string (Terrat_config.Gitlab.web_base_url config)))
    in
    let body =
      Yojson.Safe.to_string
        (`Assoc
           [
             ("client_id", `String (Terrat_config.Gitlab.app_id config));
             ("client_secret", `String (Terrat_config.Gitlab.app_secret config));
             ("code", `String code);
           ])
    in
    Http.post ~headers ~body uri
    >>| function
    | Ok (resp, body) when Http.Status.is_success (Http.Response.status resp) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> Error (`Authorize_err body))
    | Ok (resp, body) -> Error (`Authorize_err body)
    | Error err -> Error err

  let refresh ~config refresh_token =
    let open Abb.Future.Infix_monad in
    let headers =
      Http.Headers.of_list
        [
          ("user-agent", "Terrateam");
          ("accept", "application/json");
          ("content-type", "application/json");
        ]
    in
    let uri =
      Uri.of_string
        (Printf.sprintf
           "%s/login/oauth/access_token"
           (Uri.to_string (Terrat_config.Gitlab.web_base_url config)))
    in
    let body =
      Yojson.Safe.to_string
        (`Assoc
           [
             ("client_id", `String (Terrat_config.Gitlab.app_id config));
             ("client_secret", `String (Terrat_config.Gitlab.app_secret config));
             ("grant_type", `String "refresh_token");
             ("refresh_token", `String refresh_token);
           ])
    in
    Http.post ~headers ~body uri
    >>| function
    | Ok (resp, body) when Http.Status.is_success (Http.Response.status resp) -> (
        match Response.of_yojson (Yojson.Safe.from_string body) with
        | Ok value -> Ok value
        | Error _ -> (
            match Response_err.of_yojson (Yojson.Safe.from_string body) with
            | Ok { Response_err.error = "bad_refresh_token"; _ } -> Error `Bad_refresh_token
            | _ -> Error (`Refresh_err body)))
    | Ok (resp, body) -> Error (`Refresh_err body)
    | Error err -> Error err
end

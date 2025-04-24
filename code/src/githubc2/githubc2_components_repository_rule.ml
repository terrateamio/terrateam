type t =
  | Repository_rule_creation of Githubc2_components_repository_rule_creation.t
  | Repository_rule_update of Githubc2_components_repository_rule_update.t
  | Repository_rule_deletion of Githubc2_components_repository_rule_deletion.t
  | Repository_rule_required_linear_history of
      Githubc2_components_repository_rule_required_linear_history.t
  | Repository_rule_merge_queue of Githubc2_components_repository_rule_merge_queue.t
  | Repository_rule_required_deployments of
      Githubc2_components_repository_rule_required_deployments.t
  | Repository_rule_required_signatures of Githubc2_components_repository_rule_required_signatures.t
  | Repository_rule_pull_request of Githubc2_components_repository_rule_pull_request.t
  | Repository_rule_required_status_checks of
      Githubc2_components_repository_rule_required_status_checks.t
  | Repository_rule_non_fast_forward of Githubc2_components_repository_rule_non_fast_forward.t
  | Repository_rule_commit_message_pattern of
      Githubc2_components_repository_rule_commit_message_pattern.t
  | Repository_rule_commit_author_email_pattern of
      Githubc2_components_repository_rule_commit_author_email_pattern.t
  | Repository_rule_committer_email_pattern of
      Githubc2_components_repository_rule_committer_email_pattern.t
  | Repository_rule_branch_name_pattern of Githubc2_components_repository_rule_branch_name_pattern.t
  | Repository_rule_tag_name_pattern of Githubc2_components_repository_rule_tag_name_pattern.t
  | Repository_rule_file_path_restriction of
      Githubc2_components_repository_rule_file_path_restriction.t
  | Repository_rule_max_file_path_length of
      Githubc2_components_repository_rule_max_file_path_length.t
  | Repository_rule_file_extension_restriction of
      Githubc2_components_repository_rule_file_extension_restriction.t
  | Repository_rule_max_file_size of Githubc2_components_repository_rule_max_file_size.t
  | Repository_rule_workflows of Githubc2_components_repository_rule_workflows.t
  | Repository_rule_code_scanning of Githubc2_components_repository_rule_code_scanning.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Repository_rule_creation v)
           (Githubc2_components_repository_rule_creation.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_update v)
           (Githubc2_components_repository_rule_update.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_deletion v)
           (Githubc2_components_repository_rule_deletion.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_required_linear_history v)
           (Githubc2_components_repository_rule_required_linear_history.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_merge_queue v)
           (Githubc2_components_repository_rule_merge_queue.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_required_deployments v)
           (Githubc2_components_repository_rule_required_deployments.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_required_signatures v)
           (Githubc2_components_repository_rule_required_signatures.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_pull_request v)
           (Githubc2_components_repository_rule_pull_request.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_required_status_checks v)
           (Githubc2_components_repository_rule_required_status_checks.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_non_fast_forward v)
           (Githubc2_components_repository_rule_non_fast_forward.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_commit_message_pattern v)
           (Githubc2_components_repository_rule_commit_message_pattern.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_commit_author_email_pattern v)
           (Githubc2_components_repository_rule_commit_author_email_pattern.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_committer_email_pattern v)
           (Githubc2_components_repository_rule_committer_email_pattern.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_branch_name_pattern v)
           (Githubc2_components_repository_rule_branch_name_pattern.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_tag_name_pattern v)
           (Githubc2_components_repository_rule_tag_name_pattern.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_file_path_restriction v)
           (Githubc2_components_repository_rule_file_path_restriction.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_max_file_path_length v)
           (Githubc2_components_repository_rule_max_file_path_length.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_file_extension_restriction v)
           (Githubc2_components_repository_rule_file_extension_restriction.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_max_file_size v)
           (Githubc2_components_repository_rule_max_file_size.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_workflows v)
           (Githubc2_components_repository_rule_workflows.of_yojson v));
       (fun v ->
         map
           (fun v -> Repository_rule_code_scanning v)
           (Githubc2_components_repository_rule_code_scanning.of_yojson v));
     ])

let to_yojson = function
  | Repository_rule_creation v -> Githubc2_components_repository_rule_creation.to_yojson v
  | Repository_rule_update v -> Githubc2_components_repository_rule_update.to_yojson v
  | Repository_rule_deletion v -> Githubc2_components_repository_rule_deletion.to_yojson v
  | Repository_rule_required_linear_history v ->
      Githubc2_components_repository_rule_required_linear_history.to_yojson v
  | Repository_rule_merge_queue v -> Githubc2_components_repository_rule_merge_queue.to_yojson v
  | Repository_rule_required_deployments v ->
      Githubc2_components_repository_rule_required_deployments.to_yojson v
  | Repository_rule_required_signatures v ->
      Githubc2_components_repository_rule_required_signatures.to_yojson v
  | Repository_rule_pull_request v -> Githubc2_components_repository_rule_pull_request.to_yojson v
  | Repository_rule_required_status_checks v ->
      Githubc2_components_repository_rule_required_status_checks.to_yojson v
  | Repository_rule_non_fast_forward v ->
      Githubc2_components_repository_rule_non_fast_forward.to_yojson v
  | Repository_rule_commit_message_pattern v ->
      Githubc2_components_repository_rule_commit_message_pattern.to_yojson v
  | Repository_rule_commit_author_email_pattern v ->
      Githubc2_components_repository_rule_commit_author_email_pattern.to_yojson v
  | Repository_rule_committer_email_pattern v ->
      Githubc2_components_repository_rule_committer_email_pattern.to_yojson v
  | Repository_rule_branch_name_pattern v ->
      Githubc2_components_repository_rule_branch_name_pattern.to_yojson v
  | Repository_rule_tag_name_pattern v ->
      Githubc2_components_repository_rule_tag_name_pattern.to_yojson v
  | Repository_rule_file_path_restriction v ->
      Githubc2_components_repository_rule_file_path_restriction.to_yojson v
  | Repository_rule_max_file_path_length v ->
      Githubc2_components_repository_rule_max_file_path_length.to_yojson v
  | Repository_rule_file_extension_restriction v ->
      Githubc2_components_repository_rule_file_extension_restriction.to_yojson v
  | Repository_rule_max_file_size v -> Githubc2_components_repository_rule_max_file_size.to_yojson v
  | Repository_rule_workflows v -> Githubc2_components_repository_rule_workflows.to_yojson v
  | Repository_rule_code_scanning v -> Githubc2_components_repository_rule_code_scanning.to_yojson v

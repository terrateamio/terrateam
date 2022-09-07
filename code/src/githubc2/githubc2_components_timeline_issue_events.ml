type t =
  | Labeled_issue_event of Githubc2_components_labeled_issue_event.t
  | Unlabeled_issue_event of Githubc2_components_unlabeled_issue_event.t
  | Milestoned_issue_event of Githubc2_components_milestoned_issue_event.t
  | Demilestoned_issue_event of Githubc2_components_demilestoned_issue_event.t
  | Renamed_issue_event of Githubc2_components_renamed_issue_event.t
  | Review_requested_issue_event of Githubc2_components_review_requested_issue_event.t
  | Review_request_removed_issue_event of Githubc2_components_review_request_removed_issue_event.t
  | Review_dismissed_issue_event of Githubc2_components_review_dismissed_issue_event.t
  | Locked_issue_event of Githubc2_components_locked_issue_event.t
  | Added_to_project_issue_event of Githubc2_components_added_to_project_issue_event.t
  | Moved_column_in_project_issue_event of Githubc2_components_moved_column_in_project_issue_event.t
  | Removed_from_project_issue_event of Githubc2_components_removed_from_project_issue_event.t
  | Converted_note_to_issue_issue_event of Githubc2_components_converted_note_to_issue_issue_event.t
  | Timeline_comment_event of Githubc2_components_timeline_comment_event.t
  | Timeline_cross_referenced_event of Githubc2_components_timeline_cross_referenced_event.t
  | Timeline_committed_event of Githubc2_components_timeline_committed_event.t
  | Timeline_reviewed_event of Githubc2_components_timeline_reviewed_event.t
  | Timeline_line_commented_event of Githubc2_components_timeline_line_commented_event.t
  | Timeline_commit_commented_event of Githubc2_components_timeline_commit_commented_event.t
  | Timeline_assigned_issue_event of Githubc2_components_timeline_assigned_issue_event.t
  | Timeline_unassigned_issue_event of Githubc2_components_timeline_unassigned_issue_event.t
  | State_change_issue_event of Githubc2_components_state_change_issue_event.t
[@@deriving show]

let of_yojson =
  Json_schema.any_of
    (let open CCResult in
    [
      (fun v ->
        map (fun v -> Labeled_issue_event v) (Githubc2_components_labeled_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Unlabeled_issue_event v)
          (Githubc2_components_unlabeled_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Milestoned_issue_event v)
          (Githubc2_components_milestoned_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Demilestoned_issue_event v)
          (Githubc2_components_demilestoned_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> Renamed_issue_event v) (Githubc2_components_renamed_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Review_requested_issue_event v)
          (Githubc2_components_review_requested_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Review_request_removed_issue_event v)
          (Githubc2_components_review_request_removed_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Review_dismissed_issue_event v)
          (Githubc2_components_review_dismissed_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> Locked_issue_event v) (Githubc2_components_locked_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Added_to_project_issue_event v)
          (Githubc2_components_added_to_project_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Moved_column_in_project_issue_event v)
          (Githubc2_components_moved_column_in_project_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Removed_from_project_issue_event v)
          (Githubc2_components_removed_from_project_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Converted_note_to_issue_issue_event v)
          (Githubc2_components_converted_note_to_issue_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_comment_event v)
          (Githubc2_components_timeline_comment_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_cross_referenced_event v)
          (Githubc2_components_timeline_cross_referenced_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_committed_event v)
          (Githubc2_components_timeline_committed_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_reviewed_event v)
          (Githubc2_components_timeline_reviewed_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_line_commented_event v)
          (Githubc2_components_timeline_line_commented_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_commit_commented_event v)
          (Githubc2_components_timeline_commit_commented_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_assigned_issue_event v)
          (Githubc2_components_timeline_assigned_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Timeline_unassigned_issue_event v)
          (Githubc2_components_timeline_unassigned_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> State_change_issue_event v)
          (Githubc2_components_state_change_issue_event.of_yojson v));
    ])

let to_yojson = function
  | Labeled_issue_event v -> Githubc2_components_labeled_issue_event.to_yojson v
  | Unlabeled_issue_event v -> Githubc2_components_unlabeled_issue_event.to_yojson v
  | Milestoned_issue_event v -> Githubc2_components_milestoned_issue_event.to_yojson v
  | Demilestoned_issue_event v -> Githubc2_components_demilestoned_issue_event.to_yojson v
  | Renamed_issue_event v -> Githubc2_components_renamed_issue_event.to_yojson v
  | Review_requested_issue_event v -> Githubc2_components_review_requested_issue_event.to_yojson v
  | Review_request_removed_issue_event v ->
      Githubc2_components_review_request_removed_issue_event.to_yojson v
  | Review_dismissed_issue_event v -> Githubc2_components_review_dismissed_issue_event.to_yojson v
  | Locked_issue_event v -> Githubc2_components_locked_issue_event.to_yojson v
  | Added_to_project_issue_event v -> Githubc2_components_added_to_project_issue_event.to_yojson v
  | Moved_column_in_project_issue_event v ->
      Githubc2_components_moved_column_in_project_issue_event.to_yojson v
  | Removed_from_project_issue_event v ->
      Githubc2_components_removed_from_project_issue_event.to_yojson v
  | Converted_note_to_issue_issue_event v ->
      Githubc2_components_converted_note_to_issue_issue_event.to_yojson v
  | Timeline_comment_event v -> Githubc2_components_timeline_comment_event.to_yojson v
  | Timeline_cross_referenced_event v ->
      Githubc2_components_timeline_cross_referenced_event.to_yojson v
  | Timeline_committed_event v -> Githubc2_components_timeline_committed_event.to_yojson v
  | Timeline_reviewed_event v -> Githubc2_components_timeline_reviewed_event.to_yojson v
  | Timeline_line_commented_event v -> Githubc2_components_timeline_line_commented_event.to_yojson v
  | Timeline_commit_commented_event v ->
      Githubc2_components_timeline_commit_commented_event.to_yojson v
  | Timeline_assigned_issue_event v -> Githubc2_components_timeline_assigned_issue_event.to_yojson v
  | Timeline_unassigned_issue_event v ->
      Githubc2_components_timeline_unassigned_issue_event.to_yojson v
  | State_change_issue_event v -> Githubc2_components_state_change_issue_event.to_yojson v

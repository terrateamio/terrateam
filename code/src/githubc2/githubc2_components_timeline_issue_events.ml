type t =
  | V0 of Githubc2_components_labeled_issue_event.t
  | V1 of Githubc2_components_unlabeled_issue_event.t
  | V2 of Githubc2_components_milestoned_issue_event.t
  | V3 of Githubc2_components_demilestoned_issue_event.t
  | V4 of Githubc2_components_renamed_issue_event.t
  | V5 of Githubc2_components_review_requested_issue_event.t
  | V6 of Githubc2_components_review_request_removed_issue_event.t
  | V7 of Githubc2_components_review_dismissed_issue_event.t
  | V8 of Githubc2_components_locked_issue_event.t
  | V9 of Githubc2_components_added_to_project_issue_event.t
  | V10 of Githubc2_components_moved_column_in_project_issue_event.t
  | V11 of Githubc2_components_removed_from_project_issue_event.t
  | V12 of Githubc2_components_converted_note_to_issue_issue_event.t
  | V13 of Githubc2_components_timeline_comment_event.t
  | V14 of Githubc2_components_timeline_cross_referenced_event.t
  | V15 of Githubc2_components_timeline_committed_event.t
  | V16 of Githubc2_components_timeline_reviewed_event.t
  | V17 of Githubc2_components_timeline_line_commented_event.t
  | V18 of Githubc2_components_timeline_commit_commented_event.t
  | V19 of Githubc2_components_timeline_assigned_issue_event.t
  | V20 of Githubc2_components_timeline_unassigned_issue_event.t
  | V21 of Githubc2_components_state_change_issue_event.t
[@@deriving show]

let of_yojson =
  Json_schema.any_of
    (let open CCResult in
    [
      (fun v -> map (fun v -> V0 v) (Githubc2_components_labeled_issue_event.of_yojson v));
      (fun v -> map (fun v -> V1 v) (Githubc2_components_unlabeled_issue_event.of_yojson v));
      (fun v -> map (fun v -> V2 v) (Githubc2_components_milestoned_issue_event.of_yojson v));
      (fun v -> map (fun v -> V3 v) (Githubc2_components_demilestoned_issue_event.of_yojson v));
      (fun v -> map (fun v -> V4 v) (Githubc2_components_renamed_issue_event.of_yojson v));
      (fun v -> map (fun v -> V5 v) (Githubc2_components_review_requested_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> V6 v) (Githubc2_components_review_request_removed_issue_event.of_yojson v));
      (fun v -> map (fun v -> V7 v) (Githubc2_components_review_dismissed_issue_event.of_yojson v));
      (fun v -> map (fun v -> V8 v) (Githubc2_components_locked_issue_event.of_yojson v));
      (fun v -> map (fun v -> V9 v) (Githubc2_components_added_to_project_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> V10 v) (Githubc2_components_moved_column_in_project_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> V11 v) (Githubc2_components_removed_from_project_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> V12 v) (Githubc2_components_converted_note_to_issue_issue_event.of_yojson v));
      (fun v -> map (fun v -> V13 v) (Githubc2_components_timeline_comment_event.of_yojson v));
      (fun v ->
        map (fun v -> V14 v) (Githubc2_components_timeline_cross_referenced_event.of_yojson v));
      (fun v -> map (fun v -> V15 v) (Githubc2_components_timeline_committed_event.of_yojson v));
      (fun v -> map (fun v -> V16 v) (Githubc2_components_timeline_reviewed_event.of_yojson v));
      (fun v ->
        map (fun v -> V17 v) (Githubc2_components_timeline_line_commented_event.of_yojson v));
      (fun v ->
        map (fun v -> V18 v) (Githubc2_components_timeline_commit_commented_event.of_yojson v));
      (fun v ->
        map (fun v -> V19 v) (Githubc2_components_timeline_assigned_issue_event.of_yojson v));
      (fun v ->
        map (fun v -> V20 v) (Githubc2_components_timeline_unassigned_issue_event.of_yojson v));
      (fun v -> map (fun v -> V21 v) (Githubc2_components_state_change_issue_event.of_yojson v));
    ])

let to_yojson = function
  | V0 v -> Githubc2_components_labeled_issue_event.to_yojson v
  | V1 v -> Githubc2_components_unlabeled_issue_event.to_yojson v
  | V2 v -> Githubc2_components_milestoned_issue_event.to_yojson v
  | V3 v -> Githubc2_components_demilestoned_issue_event.to_yojson v
  | V4 v -> Githubc2_components_renamed_issue_event.to_yojson v
  | V5 v -> Githubc2_components_review_requested_issue_event.to_yojson v
  | V6 v -> Githubc2_components_review_request_removed_issue_event.to_yojson v
  | V7 v -> Githubc2_components_review_dismissed_issue_event.to_yojson v
  | V8 v -> Githubc2_components_locked_issue_event.to_yojson v
  | V9 v -> Githubc2_components_added_to_project_issue_event.to_yojson v
  | V10 v -> Githubc2_components_moved_column_in_project_issue_event.to_yojson v
  | V11 v -> Githubc2_components_removed_from_project_issue_event.to_yojson v
  | V12 v -> Githubc2_components_converted_note_to_issue_issue_event.to_yojson v
  | V13 v -> Githubc2_components_timeline_comment_event.to_yojson v
  | V14 v -> Githubc2_components_timeline_cross_referenced_event.to_yojson v
  | V15 v -> Githubc2_components_timeline_committed_event.to_yojson v
  | V16 v -> Githubc2_components_timeline_reviewed_event.to_yojson v
  | V17 v -> Githubc2_components_timeline_line_commented_event.to_yojson v
  | V18 v -> Githubc2_components_timeline_commit_commented_event.to_yojson v
  | V19 v -> Githubc2_components_timeline_assigned_issue_event.to_yojson v
  | V20 v -> Githubc2_components_timeline_unassigned_issue_event.to_yojson v
  | V21 v -> Githubc2_components_state_change_issue_event.to_yojson v

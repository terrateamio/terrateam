type t =
  | Labeled_issue_event of Githubc2_components_labeled_issue_event.t
  | Unlabeled_issue_event of Githubc2_components_unlabeled_issue_event.t
  | Assigned_issue_event of Githubc2_components_assigned_issue_event.t
  | Unassigned_issue_event of Githubc2_components_unassigned_issue_event.t
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
[@@deriving show, eq]

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
        map (fun v -> Assigned_issue_event v) (Githubc2_components_assigned_issue_event.of_yojson v));
      (fun v ->
        map
          (fun v -> Unassigned_issue_event v)
          (Githubc2_components_unassigned_issue_event.of_yojson v));
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
    ])

let to_yojson = function
  | Labeled_issue_event v -> Githubc2_components_labeled_issue_event.to_yojson v
  | Unlabeled_issue_event v -> Githubc2_components_unlabeled_issue_event.to_yojson v
  | Assigned_issue_event v -> Githubc2_components_assigned_issue_event.to_yojson v
  | Unassigned_issue_event v -> Githubc2_components_unassigned_issue_event.to_yojson v
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

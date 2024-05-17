type t =
  | Pull_request_assigned of Terrat_github_webhooks_pull_request_assigned.t
  | Pull_request_auto_merge_disabled of Terrat_github_webhooks_pull_request_auto_merge_disabled.t
  | Pull_request_auto_merge_enabled of Terrat_github_webhooks_pull_request_auto_merge_enabled.t
  | Pull_request_closed of Terrat_github_webhooks_pull_request_closed.t
  | Pull_request_converted_to_draft of Terrat_github_webhooks_pull_request_converted_to_draft.t
  | Pull_request_edited of Terrat_github_webhooks_pull_request_edited.t
  | Pull_request_labeled of Terrat_github_webhooks_pull_request_labeled.t
  | Pull_request_locked of Terrat_github_webhooks_pull_request_locked.t
  | Pull_request_milestoned of Terrat_github_webhooks_pull_request_milestoned.t
  | Pull_request_opened of Terrat_github_webhooks_pull_request_opened.t
  | Pull_request_ready_for_review of Terrat_github_webhooks_pull_request_ready_for_review.t
  | Pull_request_reopened of Terrat_github_webhooks_pull_request_reopened.t
  | Pull_request_review_request_removed of
      Terrat_github_webhooks_pull_request_review_request_removed.t
  | Pull_request_review_requested of Terrat_github_webhooks_pull_request_review_requested.t
  | Pull_request_synchronize of Terrat_github_webhooks_pull_request_synchronize.t
  | Pull_request_unassigned of Terrat_github_webhooks_pull_request_unassigned.t
  | Pull_request_unlabeled of Terrat_github_webhooks_pull_request_unlabeled.t
  | Pull_request_unlocked of Terrat_github_webhooks_pull_request_unlocked.t
  | Pull_request_review_submitted of Terrat_github_webhooks_pull_request_review_submitted.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v ->
         map
           (fun v -> Pull_request_assigned v)
           (Terrat_github_webhooks_pull_request_assigned.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_auto_merge_disabled v)
           (Terrat_github_webhooks_pull_request_auto_merge_disabled.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_auto_merge_enabled v)
           (Terrat_github_webhooks_pull_request_auto_merge_enabled.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_closed v)
           (Terrat_github_webhooks_pull_request_closed.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_converted_to_draft v)
           (Terrat_github_webhooks_pull_request_converted_to_draft.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_edited v)
           (Terrat_github_webhooks_pull_request_edited.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_labeled v)
           (Terrat_github_webhooks_pull_request_labeled.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_locked v)
           (Terrat_github_webhooks_pull_request_locked.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_milestoned v)
           (Terrat_github_webhooks_pull_request_milestoned.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_opened v)
           (Terrat_github_webhooks_pull_request_opened.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_ready_for_review v)
           (Terrat_github_webhooks_pull_request_ready_for_review.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_reopened v)
           (Terrat_github_webhooks_pull_request_reopened.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_review_request_removed v)
           (Terrat_github_webhooks_pull_request_review_request_removed.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_review_requested v)
           (Terrat_github_webhooks_pull_request_review_requested.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_synchronize v)
           (Terrat_github_webhooks_pull_request_synchronize.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_unassigned v)
           (Terrat_github_webhooks_pull_request_unassigned.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_unlabeled v)
           (Terrat_github_webhooks_pull_request_unlabeled.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_unlocked v)
           (Terrat_github_webhooks_pull_request_unlocked.of_yojson v));
       (fun v ->
         map
           (fun v -> Pull_request_review_submitted v)
           (Terrat_github_webhooks_pull_request_review_submitted.of_yojson v));
     ])

let to_yojson = function
  | Pull_request_assigned v -> Terrat_github_webhooks_pull_request_assigned.to_yojson v
  | Pull_request_auto_merge_disabled v ->
      Terrat_github_webhooks_pull_request_auto_merge_disabled.to_yojson v
  | Pull_request_auto_merge_enabled v ->
      Terrat_github_webhooks_pull_request_auto_merge_enabled.to_yojson v
  | Pull_request_closed v -> Terrat_github_webhooks_pull_request_closed.to_yojson v
  | Pull_request_converted_to_draft v ->
      Terrat_github_webhooks_pull_request_converted_to_draft.to_yojson v
  | Pull_request_edited v -> Terrat_github_webhooks_pull_request_edited.to_yojson v
  | Pull_request_labeled v -> Terrat_github_webhooks_pull_request_labeled.to_yojson v
  | Pull_request_locked v -> Terrat_github_webhooks_pull_request_locked.to_yojson v
  | Pull_request_milestoned v -> Terrat_github_webhooks_pull_request_milestoned.to_yojson v
  | Pull_request_opened v -> Terrat_github_webhooks_pull_request_opened.to_yojson v
  | Pull_request_ready_for_review v ->
      Terrat_github_webhooks_pull_request_ready_for_review.to_yojson v
  | Pull_request_reopened v -> Terrat_github_webhooks_pull_request_reopened.to_yojson v
  | Pull_request_review_request_removed v ->
      Terrat_github_webhooks_pull_request_review_request_removed.to_yojson v
  | Pull_request_review_requested v ->
      Terrat_github_webhooks_pull_request_review_requested.to_yojson v
  | Pull_request_synchronize v -> Terrat_github_webhooks_pull_request_synchronize.to_yojson v
  | Pull_request_unassigned v -> Terrat_github_webhooks_pull_request_unassigned.to_yojson v
  | Pull_request_unlabeled v -> Terrat_github_webhooks_pull_request_unlabeled.to_yojson v
  | Pull_request_unlocked v -> Terrat_github_webhooks_pull_request_unlocked.to_yojson v
  | Pull_request_review_submitted v ->
      Terrat_github_webhooks_pull_request_review_submitted.to_yojson v

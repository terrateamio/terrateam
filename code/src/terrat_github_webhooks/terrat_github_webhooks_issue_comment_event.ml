type t =
  | Issue_comment_created of Terrat_github_webhooks_issue_comment_created.t
  | Issue_comment_deleted of Terrat_github_webhooks_issue_comment_deleted.t
  | Issue_comment_edited of Terrat_github_webhooks_issue_comment_edited.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Issue_comment_created v)
          (Terrat_github_webhooks_issue_comment_created.of_yojson v));
      (fun v ->
        map
          (fun v -> Issue_comment_deleted v)
          (Terrat_github_webhooks_issue_comment_deleted.of_yojson v));
      (fun v ->
        map
          (fun v -> Issue_comment_edited v)
          (Terrat_github_webhooks_issue_comment_edited.of_yojson v));
    ])

let to_yojson = function
  | Issue_comment_created v -> Terrat_github_webhooks_issue_comment_created.to_yojson v
  | Issue_comment_deleted v -> Terrat_github_webhooks_issue_comment_deleted.to_yojson v
  | Issue_comment_edited v -> Terrat_github_webhooks_issue_comment_edited.to_yojson v

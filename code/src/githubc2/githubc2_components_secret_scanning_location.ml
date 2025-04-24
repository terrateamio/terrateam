module Primary = struct
  module Details = struct
    type t =
      | Secret_scanning_location_commit of Githubc2_components_secret_scanning_location_commit.t
      | Secret_scanning_location_wiki_commit of
          Githubc2_components_secret_scanning_location_wiki_commit.t
      | Secret_scanning_location_issue_title of
          Githubc2_components_secret_scanning_location_issue_title.t
      | Secret_scanning_location_issue_body of
          Githubc2_components_secret_scanning_location_issue_body.t
      | Secret_scanning_location_issue_comment of
          Githubc2_components_secret_scanning_location_issue_comment.t
      | Secret_scanning_location_discussion_title of
          Githubc2_components_secret_scanning_location_discussion_title.t
      | Secret_scanning_location_discussion_body of
          Githubc2_components_secret_scanning_location_discussion_body.t
      | Secret_scanning_location_discussion_comment of
          Githubc2_components_secret_scanning_location_discussion_comment.t
      | Secret_scanning_location_pull_request_title of
          Githubc2_components_secret_scanning_location_pull_request_title.t
      | Secret_scanning_location_pull_request_body of
          Githubc2_components_secret_scanning_location_pull_request_body.t
      | Secret_scanning_location_pull_request_comment of
          Githubc2_components_secret_scanning_location_pull_request_comment.t
      | Secret_scanning_location_pull_request_review of
          Githubc2_components_secret_scanning_location_pull_request_review.t
      | Secret_scanning_location_pull_request_review_comment of
          Githubc2_components_secret_scanning_location_pull_request_review_comment.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v ->
             map
               (fun v -> Secret_scanning_location_commit v)
               (Githubc2_components_secret_scanning_location_commit.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_wiki_commit v)
               (Githubc2_components_secret_scanning_location_wiki_commit.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_issue_title v)
               (Githubc2_components_secret_scanning_location_issue_title.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_issue_body v)
               (Githubc2_components_secret_scanning_location_issue_body.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_issue_comment v)
               (Githubc2_components_secret_scanning_location_issue_comment.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_discussion_title v)
               (Githubc2_components_secret_scanning_location_discussion_title.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_discussion_body v)
               (Githubc2_components_secret_scanning_location_discussion_body.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_discussion_comment v)
               (Githubc2_components_secret_scanning_location_discussion_comment.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_pull_request_title v)
               (Githubc2_components_secret_scanning_location_pull_request_title.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_pull_request_body v)
               (Githubc2_components_secret_scanning_location_pull_request_body.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_pull_request_comment v)
               (Githubc2_components_secret_scanning_location_pull_request_comment.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_pull_request_review v)
               (Githubc2_components_secret_scanning_location_pull_request_review.of_yojson v));
           (fun v ->
             map
               (fun v -> Secret_scanning_location_pull_request_review_comment v)
               (Githubc2_components_secret_scanning_location_pull_request_review_comment.of_yojson
                  v));
         ])

    let to_yojson = function
      | Secret_scanning_location_commit v ->
          Githubc2_components_secret_scanning_location_commit.to_yojson v
      | Secret_scanning_location_wiki_commit v ->
          Githubc2_components_secret_scanning_location_wiki_commit.to_yojson v
      | Secret_scanning_location_issue_title v ->
          Githubc2_components_secret_scanning_location_issue_title.to_yojson v
      | Secret_scanning_location_issue_body v ->
          Githubc2_components_secret_scanning_location_issue_body.to_yojson v
      | Secret_scanning_location_issue_comment v ->
          Githubc2_components_secret_scanning_location_issue_comment.to_yojson v
      | Secret_scanning_location_discussion_title v ->
          Githubc2_components_secret_scanning_location_discussion_title.to_yojson v
      | Secret_scanning_location_discussion_body v ->
          Githubc2_components_secret_scanning_location_discussion_body.to_yojson v
      | Secret_scanning_location_discussion_comment v ->
          Githubc2_components_secret_scanning_location_discussion_comment.to_yojson v
      | Secret_scanning_location_pull_request_title v ->
          Githubc2_components_secret_scanning_location_pull_request_title.to_yojson v
      | Secret_scanning_location_pull_request_body v ->
          Githubc2_components_secret_scanning_location_pull_request_body.to_yojson v
      | Secret_scanning_location_pull_request_comment v ->
          Githubc2_components_secret_scanning_location_pull_request_comment.to_yojson v
      | Secret_scanning_location_pull_request_review v ->
          Githubc2_components_secret_scanning_location_pull_request_review.to_yojson v
      | Secret_scanning_location_pull_request_review_comment v ->
          Githubc2_components_secret_scanning_location_pull_request_review_comment.to_yojson v
  end

  module Type = struct
    let t_of_yojson = function
      | `String "commit" -> Ok "commit"
      | `String "wiki_commit" -> Ok "wiki_commit"
      | `String "issue_title" -> Ok "issue_title"
      | `String "issue_body" -> Ok "issue_body"
      | `String "issue_comment" -> Ok "issue_comment"
      | `String "discussion_title" -> Ok "discussion_title"
      | `String "discussion_body" -> Ok "discussion_body"
      | `String "discussion_comment" -> Ok "discussion_comment"
      | `String "pull_request_title" -> Ok "pull_request_title"
      | `String "pull_request_body" -> Ok "pull_request_body"
      | `String "pull_request_comment" -> Ok "pull_request_comment"
      | `String "pull_request_review" -> Ok "pull_request_review"
      | `String "pull_request_review_comment" -> Ok "pull_request_review_comment"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    details : Details.t option; [@default None]
    type_ : Type.t option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

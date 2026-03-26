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
      | `String "commit" -> Ok `Commit
      | `String "discussion_body" -> Ok `Discussion_body
      | `String "discussion_comment" -> Ok `Discussion_comment
      | `String "discussion_title" -> Ok `Discussion_title
      | `String "issue_body" -> Ok `Issue_body
      | `String "issue_comment" -> Ok `Issue_comment
      | `String "issue_title" -> Ok `Issue_title
      | `String "pull_request_body" -> Ok `Pull_request_body
      | `String "pull_request_comment" -> Ok `Pull_request_comment
      | `String "pull_request_review" -> Ok `Pull_request_review
      | `String "pull_request_review_comment" -> Ok `Pull_request_review_comment
      | `String "pull_request_title" -> Ok `Pull_request_title
      | `String "wiki_commit" -> Ok `Wiki_commit
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Commit -> `String "commit"
      | `Discussion_body -> `String "discussion_body"
      | `Discussion_comment -> `String "discussion_comment"
      | `Discussion_title -> `String "discussion_title"
      | `Issue_body -> `String "issue_body"
      | `Issue_comment -> `String "issue_comment"
      | `Issue_title -> `String "issue_title"
      | `Pull_request_body -> `String "pull_request_body"
      | `Pull_request_comment -> `String "pull_request_comment"
      | `Pull_request_review -> `String "pull_request_review"
      | `Pull_request_review_comment -> `String "pull_request_review_comment"
      | `Pull_request_title -> `String "pull_request_title"
      | `Wiki_commit -> `String "wiki_commit"

    type t =
      ([ `Commit
       | `Discussion_body
       | `Discussion_comment
       | `Discussion_title
       | `Issue_body
       | `Issue_comment
       | `Issue_title
       | `Pull_request_body
       | `Pull_request_comment
       | `Pull_request_review
       | `Pull_request_review_comment
       | `Pull_request_title
       | `Wiki_commit
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    details : Details.t option; [@default None]
    type_ : Type.t option; [@default None] [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

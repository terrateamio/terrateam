module Merge_request = Gitlab_webhooks_merge_request
module Merge_request_comment_event = Gitlab_webhooks_merge_request_comment_event
module Merge_request_event = Gitlab_webhooks_merge_request_event
module Project = Gitlab_webhooks_project
module Push_event = Gitlab_webhooks_push_event
module Repository = Gitlab_webhooks_repository
module User = Gitlab_webhooks_user

module Event = struct
  type t =
    | Push_event of Gitlab_webhooks_push_event.t
    | Merge_request_comment_event of Gitlab_webhooks_merge_request_comment_event.t
    | Merge_request_event of Gitlab_webhooks_merge_request_event.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v -> map (fun v -> Push_event v) (Gitlab_webhooks_push_event.of_yojson v));
         (fun v ->
           map
             (fun v -> Merge_request_comment_event v)
             (Gitlab_webhooks_merge_request_comment_event.of_yojson v));
         (fun v ->
           map (fun v -> Merge_request_event v) (Gitlab_webhooks_merge_request_event.of_yojson v));
       ])

  let to_yojson = function
    | Push_event v -> Gitlab_webhooks_push_event.to_yojson v
    | Merge_request_comment_event v -> Gitlab_webhooks_merge_request_comment_event.to_yojson v
    | Merge_request_event v -> Gitlab_webhooks_merge_request_event.to_yojson v
end

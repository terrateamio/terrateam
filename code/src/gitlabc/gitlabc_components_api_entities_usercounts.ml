type t = {
  assigned_issues : int option; [@default None]
  assigned_merge_requests : int option; [@default None]
  merge_requests : int option; [@default None]
  review_requested_merge_requests : int option; [@default None]
  todos : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

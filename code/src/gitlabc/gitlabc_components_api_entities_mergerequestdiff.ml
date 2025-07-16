type t = {
  base_commit_sha : string option; [@default None]
  created_at : string option; [@default None]
  head_commit_sha : string option; [@default None]
  id : string option; [@default None]
  merge_request_id : string option; [@default None]
  patch_id_sha : string option; [@default None]
  real_size : string option; [@default None]
  start_commit_sha : string option; [@default None]
  state : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

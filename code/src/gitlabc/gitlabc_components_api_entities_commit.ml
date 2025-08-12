module Parent_ids = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  author_email : string option; [@default None]
  author_name : string option; [@default None]
  authored_date : string option; [@default None]
  committed_date : string option; [@default None]
  committer_email : string option; [@default None]
  committer_name : string option; [@default None]
  created_at : string;
  id : string;
  message : string option; [@default None]
  parent_ids : Parent_ids.t option; [@default None]
  short_id : string option; [@default None]
  title : string option; [@default None]
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

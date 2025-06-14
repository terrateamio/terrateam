module Primary = struct
  type t = {
    merge_commit_message : string option; [@default None]
    merge_when_pipeline_succeeds : bool option; [@default None]
    sha : string option; [@default None]
    should_remove_source_branch : bool option; [@default None]
    skip_merge_train : bool option; [@default None]
    squash : bool option; [@default None]
    squash_commit_message : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

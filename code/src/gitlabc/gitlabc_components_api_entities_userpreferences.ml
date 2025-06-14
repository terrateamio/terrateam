module Primary = struct
  type t = {
    id : string option; [@default None]
    pass_user_identities_to_ci_jwt : string option; [@default None]
    show_whitespace_in_diffs : string option; [@default None]
    user_id : string option; [@default None]
    view_diffs_file_by_file : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

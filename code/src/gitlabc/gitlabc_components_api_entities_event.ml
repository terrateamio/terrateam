module Primary = struct
  type t = {
    action_name : string option; [@default None]
    author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    author_id : int option; [@default None]
    author_username : string option; [@default None]
    created_at : string option; [@default None]
    id : int option; [@default None]
    imported : bool option; [@default None]
    imported_from : string option; [@default None]
    note : Gitlabc_components_api_entities_note.t option; [@default None]
    project_id : int option; [@default None]
    push_data : Gitlabc_components_api_entities_pusheventpayload.t option; [@default None]
    target_id : int option; [@default None]
    target_iid : int option; [@default None]
    target_title : string option; [@default None]
    target_type : string option; [@default None]
    wiki_page : Gitlabc_components_api_entities_wikipagebasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

module Primary = struct
  type t = {
    copilot_dotcom_chat : Githubc2_components_copilot_dotcom_chat.t option; [@default None]
    copilot_dotcom_pull_requests : Githubc2_components_copilot_dotcom_pull_requests.t option;
        [@default None]
    copilot_ide_chat : Githubc2_components_copilot_ide_chat.t option; [@default None]
    copilot_ide_code_completions : Githubc2_components_copilot_ide_code_completions.t option;
        [@default None]
    date : string;
    total_active_users : int option; [@default None]
    total_engaged_users : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

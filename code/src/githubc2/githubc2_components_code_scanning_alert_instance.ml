module Primary = struct
  module Classifications = struct
    type t = Githubc2_components_code_scanning_alert_classification.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Message = struct
    module Primary = struct
      type t = { text : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    analysis_key : string option; [@default None]
    category : string option; [@default None]
    classifications : Classifications.t option; [@default None]
    commit_sha : string option; [@default None]
    environment : string option; [@default None]
    html_url : string option; [@default None]
    location : Githubc2_components_code_scanning_alert_location.t option; [@default None]
    message : Message.t option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    state : Githubc2_components_code_scanning_alert_state.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

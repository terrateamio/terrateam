module Primary = struct
  type t = {
    analysis_key : string;
    category : string option; [@default None]
    commit_sha : string;
    created_at : string;
    deletable : bool;
    environment : string;
    error : string;
    id : int;
    ref_ : string; [@key "ref"]
    results_count : int;
    rules_count : int;
    sarif_id : string;
    tool : Githubc2_components_code_scanning_analysis_tool.t;
    url : string;
    warning : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

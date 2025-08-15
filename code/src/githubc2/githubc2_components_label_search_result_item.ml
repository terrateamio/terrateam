module Primary = struct
  type t = {
    color : string;
    default : bool;
    description : string option; [@default None]
    id : int;
    name : string;
    node_id : string;
    score : float;
    text_matches : Githubc2_components_search_result_text_matches.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

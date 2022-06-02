module Primary = struct
  module Line_numbers = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    file_size : int option; [@default None]
    git_url : string;
    html_url : string;
    language : string option; [@default None]
    last_modified_at : string option; [@default None]
    line_numbers : Line_numbers.t option; [@default None]
    name : string;
    path : string;
    repository : Githubc2_components_minimal_repository.t;
    score : float;
    sha : string;
    text_matches : Githubc2_components_search_result_text_matches.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

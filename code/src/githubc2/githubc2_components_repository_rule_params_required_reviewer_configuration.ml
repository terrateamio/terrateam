module Primary = struct
  module File_patterns = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    file_patterns : File_patterns.t;
    minimum_approvals : int;
    reviewer : Githubc2_components_repository_rule_params_reviewer.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

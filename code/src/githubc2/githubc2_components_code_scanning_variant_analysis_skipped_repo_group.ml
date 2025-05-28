module Primary = struct
  module Repositories = struct
    type t = Githubc2_components_code_scanning_variant_analysis_repository.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    repositories : Repositories.t;
    repository_count : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

module Primary = struct
  module Repositories = struct
    type t = Githubc2_components_advanced_security_active_committers_repository.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    repositories : Repositories.t;
    total_advanced_security_committers : int option; [@default None]
    total_count : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

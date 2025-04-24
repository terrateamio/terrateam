module Items = struct
  module Primary = struct
    module Default_for_new_repos = struct
      type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      configuration : Githubc2_components_code_security_configuration.t option; [@default None]
      default_for_new_repos : Default_for_new_repos.t option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]

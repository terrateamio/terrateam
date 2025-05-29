module Primary = struct
  module Errors = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Includes = struct
    type t = Gitlabc_components_api_entities_ci_lint_result_include.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Jobs = struct
    module Items = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Warnings = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    errors : Errors.t option; [@default None]
    includes : Includes.t option; [@default None]
    jobs : Jobs.t option; [@default None]
    merged_yaml : string option; [@default None]
    valid : bool option; [@default None]
    warnings : Warnings.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

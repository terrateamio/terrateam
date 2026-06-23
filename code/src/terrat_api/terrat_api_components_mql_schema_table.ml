module Columns = struct
  include
    Json_schema.Additional_properties.Make
      (Json_schema.Empty_obj)
      (Terrat_api_components_mql_schema_column)
end

type t = { columns : Columns.t } [@@deriving yojson { strict = false; meta = true }, show, eq]

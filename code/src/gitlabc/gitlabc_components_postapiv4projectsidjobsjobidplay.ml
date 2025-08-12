module Job_variables_attributes = struct
  module Items = struct
    module Primary = struct
      type t = {
        key : string;
        value : string;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { job_variables_attributes : Job_variables_attributes.t option [@default None] }
[@@deriving yojson { strict = false; meta = true }, show, eq]

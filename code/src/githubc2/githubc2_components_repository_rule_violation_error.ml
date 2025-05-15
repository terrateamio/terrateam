module Primary = struct
  module Metadata_ = struct
    module Primary = struct
      module Secret_scanning = struct
        module Primary = struct
          module Bypass_placeholders = struct
            module Items = struct
              module Primary = struct
                type t = {
                  placeholder_id : string option; [@default None]
                  token_type : string option; [@default None]
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = { bypass_placeholders : Bypass_placeholders.t option [@default None] }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = { secret_scanning : Secret_scanning.t option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    documentation_url : string option; [@default None]
    message : string option; [@default None]
    metadata : Metadata_.t option; [@default None]
    status : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

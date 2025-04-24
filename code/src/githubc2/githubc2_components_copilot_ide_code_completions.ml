module Primary = struct
  module Editors = struct
    module Items = struct
      module Primary = struct
        module Models = struct
          module Items = struct
            module Primary = struct
              module Languages = struct
                module Items = struct
                  module Primary = struct
                    type t = {
                      name : string option; [@default None]
                      total_code_acceptances : int option; [@default None]
                      total_code_lines_accepted : int option; [@default None]
                      total_code_lines_suggested : int option; [@default None]
                      total_code_suggestions : int option; [@default None]
                      total_engaged_users : int option; [@default None]
                    }
                    [@@deriving yojson { strict = false; meta = true }, show, eq]
                  end

                  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
                end

                type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              type t = {
                custom_model_training_date : string option; [@default None]
                is_custom_model : bool option; [@default None]
                languages : Languages.t option; [@default None]
                name : string option; [@default None]
                total_engaged_users : int option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          models : Models.t option; [@default None]
          name : string option; [@default None]
          total_engaged_users : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Languages = struct
    module Items = struct
      module Primary = struct
        type t = {
          name : string option; [@default None]
          total_engaged_users : int option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    editors : Editors.t option; [@default None]
    languages : Languages.t option; [@default None]
    total_engaged_users : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

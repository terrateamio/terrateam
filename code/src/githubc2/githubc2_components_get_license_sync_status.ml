module Primary = struct
  module Server_instances = struct
    module Items = struct
      module Primary = struct
        module Last_sync = struct
          module Primary = struct
            type t = {
              date : string option; [@default None]
              error : string option; [@default None]
              status : string option; [@default None]
            }
            [@@deriving yojson { strict = false; meta = true }, show]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          hostname : string option; [@default None]
          last_sync : Last_sync.t option; [@default None]
          server_id : string option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = { server_instances : Server_instances.t option [@default None] }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

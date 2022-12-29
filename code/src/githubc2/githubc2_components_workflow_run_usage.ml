module Primary = struct
  module Billable = struct
    module Primary = struct
      module MACOS = struct
        module Primary = struct
          module Job_runs = struct
            module Items = struct
              module Primary = struct
                type t = {
                  duration_ms : int;
                  job_id : int;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            job_runs : Job_runs.t option; [@default None]
            jobs : int;
            total_ms : int;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module UBUNTU = struct
        module Primary = struct
          module Job_runs = struct
            module Items = struct
              module Primary = struct
                type t = {
                  duration_ms : int;
                  job_id : int;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            job_runs : Job_runs.t option; [@default None]
            jobs : int;
            total_ms : int;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module WINDOWS = struct
        module Primary = struct
          module Job_runs = struct
            module Items = struct
              module Primary = struct
                type t = {
                  duration_ms : int;
                  job_id : int;
                }
                [@@deriving yojson { strict = false; meta = true }, show, eq]
              end

              include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
            end

            type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            job_runs : Job_runs.t option; [@default None]
            jobs : int;
            total_ms : int;
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = {
        macos : MACOS.t option; [@default None] [@key "MACOS"]
        ubuntu : UBUNTU.t option; [@default None] [@key "UBUNTU"]
        windows : WINDOWS.t option; [@default None] [@key "WINDOWS"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    billable : Billable.t;
    run_duration_ms : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

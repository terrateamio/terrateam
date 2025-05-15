module Primary = struct
  module Backfill_scans = struct
    type t = Githubc2_components_secret_scanning_scan.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Custom_pattern_backfill_scans = struct
    module Items = struct
      module All_of = struct
        module Primary = struct
          type t = {
            completed_at : string option; [@default None]
            pattern_name : string option; [@default None]
            pattern_scope : string option; [@default None]
            started_at : string option; [@default None]
            status : string option; [@default None]
            type_ : string option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module T = struct
        module Primary = struct
          type t = {
            completed_at : string option; [@default None]
            pattern_name : string option; [@default None]
            pattern_scope : string option; [@default None]
            started_at : string option; [@default None]
            status : string option; [@default None]
            type_ : string option; [@default None] [@key "type"]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      type t = T.t [@@deriving yojson { strict = false; meta = true }, show, eq]

      let of_yojson json =
        let open CCResult in
        flat_map (fun _ -> T.of_yojson json) (All_of.of_yojson json)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Incremental_scans = struct
    type t = Githubc2_components_secret_scanning_scan.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pattern_update_scans = struct
    type t = Githubc2_components_secret_scanning_scan.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    backfill_scans : Backfill_scans.t option; [@default None]
    custom_pattern_backfill_scans : Custom_pattern_backfill_scans.t option; [@default None]
    incremental_scans : Incremental_scans.t option; [@default None]
    pattern_update_scans : Pattern_update_scans.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

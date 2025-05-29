module Primary = struct
  module Build_ids = struct
    type t = int list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Test_cases = struct
    type t = Gitlabc_components_testcaseentity.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    build_ids : Build_ids.t option; [@default None]
    error_count : int option; [@default None]
    failed_count : int option; [@default None]
    name : string option; [@default None]
    skipped_count : int option; [@default None]
    success_count : int option; [@default None]
    suite_error : string option; [@default None]
    test_cases : Test_cases.t option; [@default None]
    total_count : int option; [@default None]
    total_time : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

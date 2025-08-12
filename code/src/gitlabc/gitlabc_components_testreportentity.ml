module Test_suites = struct
  type t = Gitlabc_components_testsuiteentity.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  error_count : int option; [@default None]
  failed_count : int option; [@default None]
  skipped_count : int option; [@default None]
  success_count : int option; [@default None]
  test_suites : Test_suites.t option; [@default None]
  total_count : int option; [@default None]
  total_time : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]

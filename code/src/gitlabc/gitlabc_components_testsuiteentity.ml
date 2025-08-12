module Test_cases = struct
  type t = Gitlabc_components_testcaseentity.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
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

module Primary = struct
  type t = {
    test_suites : Gitlabc_components_testsuitesummaryentity.t option; [@default None]
    total : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)

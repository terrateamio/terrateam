let suite = OUnit.(>:::) "ISO8601" [
  ISO8601_PARSER.suite;
  ISO8601_PRINTER.suite;
  UTILS_TEST.suite;
]

let _ =
  OUnit.run_test_tt_main suite

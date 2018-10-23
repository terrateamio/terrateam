open Core
open Core_bench.Std

let make_bench_parsing (name, str) =
  Bench.Test.create ~name
    (fun () -> Uri.of_string str)

let parsing_benchs = [

  "small", "http://foo.com" ;

  "ipv6",
  "http://%5Bdead%3Abeef%3A%3Adead%3A0%3Abeaf%5D" ;

  "complete",
  "https://user:pass@foo.com:123/wh/at/ever?foo=1&bar=5#5";

  "query",
  "//domain?f+1=bar&+f2=bar%212";

  "path",
  "http://a/b/c/g;x?y#s";

  "urn",
  "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6";
]

let benchmarks = [
  Bench.Test.create_group ~name:"parsing"
    (List.map ~f:make_bench_parsing parsing_benchs);
]

let () = Command.run (Bench.make_command benchmarks)

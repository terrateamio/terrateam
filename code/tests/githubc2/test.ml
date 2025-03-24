(* This is a template for testing JSON parsing *)
let test_simple = Oth.test ~name:"Test simple" (fun _ -> ())
(* let data = CCIO.with_in "/tmp/foo.json" CCIO.read_all in *)
(* let json = Yojson.Safe.from_string data in *)
(* match Githubc2_components.Pull_request.of_yojson json with *)
(* | Ok _ -> () *)
(* | Error err -> *)
(*     Printf.eprintf "%s\n%!" err; *)
(*     assert false) *)

let test = Oth.parallel [ test_simple ]

let () =
  Random.self_init ();
  Oth.run test

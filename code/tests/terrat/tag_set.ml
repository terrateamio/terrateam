let test_simple =
  Oth.test ~name:"Test simple" (fun _ ->
      let query = Terrat_tag_set.of_list [] in
      let db = Terrat_tag_set.of_list [ "a"; "b"; "c" ] in
      Oth.Assert.true_ "Terrat_tag_set.match_ ~query db" (Terrat_tag_set.match_ ~query db))

let test_of_empty_string =
  Oth.test ~name:"Test of empty string" (fun _ ->
      let query = Terrat_tag_set.of_string "" in
      Oth.Assert.Eq.int ~expected:0 ~actual:(List.length (Terrat_tag_set.to_list query)))

let test = Oth.parallel [ test_simple; test_of_empty_string ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)

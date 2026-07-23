let parse s =
  match Terrat_tier.of_yojson (Yojson.Safe.from_string s) with
  | Ok t -> t
  | Error err -> raise (Failure err)

let test_empty_features =
  Oth.test ~name:"Empty features" (fun _ ->
      let t = parse "{}" in
      assert (t.Terrat_tier.num_users_per_month = CCInt.max_int);
      assert (t.Terrat_tier.runs_per_month = CCInt.max_int);
      assert (t.Terrat_tier.private_runners = CCInt.max_int))

let test_free_tier_features =
  Oth.test ~name:"Free tier features" (fun _ ->
      let t = parse "{\"runs_per_month\":50,\"num_users_per_month\":3,\"private_runners\":1}" in
      assert (t.Terrat_tier.num_users_per_month = 3);
      assert (t.Terrat_tier.runs_per_month = 50);
      assert (t.Terrat_tier.private_runners = 1))

let test_unknown_fields =
  Oth.test ~name:"Unknown fields are ignored" (fun _ ->
      let t = parse "{\"num_users_per_month\":3,\"some_future_feature\":true}" in
      assert (t.Terrat_tier.num_users_per_month = 3))

let test = Oth.parallel [ test_empty_features; test_free_tier_features; test_unknown_fields ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ test

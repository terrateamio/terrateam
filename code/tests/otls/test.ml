let test_simple =
  Oth.test
    ~name:"Simple test"
    (fun _ ->
       let client = Otls.Tls.client () in
       let cfg = Otls.Tls_config.create () in
       assert (Ok () = Otls.configure client cfg);
       Otls.Tls_config.destroy cfg;
       Otls.Tls.destroy client)

let test =
  Oth.parallel
    [ test_simple
    ]

let () =
  Random.self_init ();
  Oth.run test

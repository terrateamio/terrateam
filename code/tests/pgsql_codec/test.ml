let test_frontend_encode =
  Oth.test ~desc:"Frontend encode" ~name:"Frontend encode" (fun _ ->
      let frame = Pgsql_codec.Frame.Frontend.Terminate in
      let buf = Buffer.create 1024 in
      Pgsql_codec.Encode.frontend_msg buf frame;
      assert (Buffer.length buf = 5))

let test = Oth.parallel [ test_frontend_encode ]

let () = Oth.run test

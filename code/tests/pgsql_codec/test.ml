let test_frontend_encode =
  Oth.test ~desc:"Frontend encode" ~name:"Frontend encode" (fun _ ->
      let frame = Pgsql_codec.Frame.Frontend.Terminate in
      let buf = Buffer.create 1024 in
      Pgsql_codec.Encode.frontend_msg buf frame;
      assert (Buffer.length buf = 5))

let test_partial_msg_decode =
  Oth.test ~desc:"Partial Decode Msg" ~name:"Partial Decode Msg" (fun _ ->
      let decoder = Pgsql_codec.Decode.create () in
      let msg1 = Bytes.of_string "D\000\000\000 \000\002\000\000\000\016Testy McTestface\000\000" in
      let msg2 = Bytes.of_string "\000\00236" in
      let res = Pgsql_codec.Decode.backend_msg decoder msg1 ~pos:0 ~len:(Bytes.length msg1) in
      assert (res = Ok []);
      let res = Pgsql_codec.Decode.backend_msg decoder msg2 ~pos:0 ~len:(Bytes.length msg2) in
      assert (res = Ok Pgsql_codec.Frame.Backend.[ DataRow { data = [ "Testy McTestface"; "36" ] } ]))

let test = Oth.parallel [ test_frontend_encode; test_partial_msg_decode ]

let () = Oth.run test

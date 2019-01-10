let homepage_rt = Furi.rel
let homepage_slash_rt = Furi.(rel / "")
let hello_rt = Furi.(rel / "hello" /% Path.string)
let goodbye_rt = Furi.(rel / "goodbye" /% Path.string)
let query_rt = Furi.(rel /? Query.string "name")

let handle_hello_name = Printf.sprintf "Hello %s"
let handle_goodbye_name = Printf.sprintf "Goodbye %s"
let handle_homepage = Printf.sprintf "Homepage"
let handle_homepage_slash = Printf.sprintf "Homepage Slash"
let handle_query = Printf.sprintf "Query %s"

let router =
  Furi.(match_uri
          ~default:(fun _ -> failwith "This is not a valid path.")
          [ query_rt --> handle_query
          ; homepage_rt --> handle_homepage
          ; homepage_slash_rt --> handle_homepage_slash
          ; hello_rt --> handle_hello_name
          ; goodbye_rt --> handle_goodbye_name
          ])

let route_hello =
  Oth.test
    ~desc:"Route to the hello path"
    ~name:"Route hello"
    (fun _ ->
       let uri = Uri.of_string "http://test.com/hello/there" in
       let resp = router uri in
       assert (resp = "Hello there"))

let route_goodbye =
  Oth.test
    ~desc:"Route to the goodbye path"
    ~name:"Route goodbye"
    (fun _ ->
       let uri = Uri.of_string "http://test.com/goodbye/you" in
       let resp = router uri in
       assert (resp = "Goodbye you"))

let route_homepage =
  Oth.test
    ~desc:"Route to the homepage path"
    ~name:"Route homepage"
    (fun _ ->
       let uri = Uri.of_string "http://test.com" in
       let resp = router uri in
       assert (resp = "Homepage"))

let route_homepage_slash =
  Oth.test
    ~desc:"Route to the homepage path with ending slash"
    ~name:"Route homepage slash"
    (fun _ ->
       let uri = Uri.of_string "http://test.com/" in
       let resp = router uri in
       assert (resp = "Homepage Slash"))

let route_query =
  Oth.test
    ~desc:"Route with query"
    ~name:"Route query"
    (fun _ ->
       let uri = Uri.of_string "http://test.com?name=foobar" in
       let resp = router uri in
       assert (resp = "Query foobar"))

let test =
  Oth.parallel
    [ route_hello
    ; route_goodbye
    ; route_homepage
    ; route_homepage_slash
    ; route_query
    ]

let () =
  Random.self_init ();
  Oth.run test

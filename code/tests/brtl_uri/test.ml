(* [Brtl_uri.merge_base] joins a request's base URI with its path+query. The base commonly carries a
   bare "/" path ({!Brtl_ctx.uri_base} defaults to it), so a raw concatenation of the two paths emits
   a doubled separator ("//api/v1/…") which servers 404. Pagination is where this surfaces: the link
   header is only built once a result set spans a page, so a deployment 404s its own next-page link
   the moment any collection exceeds the page size. *)

let test_base_root_path_no_double_slash =
  Oth.test ~name:"base '/' + absolute path does not double the separator" (fun _ ->
      let merged =
        Brtl_uri.merge_base
          ~base:(Uri.of_string "http://localhost:8080/")
          (Uri.of_string "/api/v1/tenants/abc/states?limit=100")
      in
      Oth.Assert.Eq.string
        ~expected:"http://localhost:8080/api/v1/tenants/abc/states?limit=100"
        ~actual:(Uri.to_string merged))

let test_base_with_prefix_path =
  Oth.test ~name:"base with a path prefix joins with exactly one separator" (fun _ ->
      let merged =
        Brtl_uri.merge_base
          ~base:(Uri.of_string "https://example.com/sg/")
          (Uri.of_string "/api/v1/states")
      in
      Oth.Assert.Eq.string
        ~expected:"https://example.com/sg/api/v1/states"
        ~actual:(Uri.to_string merged))

let test_base_no_trailing_slash =
  Oth.test ~name:"base without a trailing slash still joins with one separator" (fun _ ->
      let merged =
        Brtl_uri.merge_base
          ~base:(Uri.of_string "https://example.com/sg")
          (Uri.of_string "/api/v1/states")
      in
      Oth.Assert.Eq.string
        ~expected:"https://example.com/sg/api/v1/states"
        ~actual:(Uri.to_string merged))

let test_query_is_taken_from_uri =
  Oth.test ~name:"the query comes from the request uri, not the base" (fun _ ->
      let merged =
        Brtl_uri.merge_base
          ~base:(Uri.of_string "http://localhost:8080/?ignored=1")
          (Uri.of_string "/api/v1/states?page=n&page=x&limit=100")
      in
      Oth.Assert.Eq.string
        ~expected:"http://localhost:8080/api/v1/states?page=n&page=x&limit=100"
        ~actual:(Uri.to_string merged))

let test =
  Oth.parallel
    [
      test_base_root_path_no_double_slash;
      test_base_with_prefix_path;
      test_base_no_trailing_slash;
      test_query_is_taken_from_uri;
    ]

let () = Oth.run ~file:__FILE__ test

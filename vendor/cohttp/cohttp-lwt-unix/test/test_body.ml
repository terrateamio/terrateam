open Lwt
open Lwt.Infix
open OUnit
module Body = Cohttp_lwt.Body

let run_test f =
  Lwt.try_bind f (fun () -> return `Ok) (fun exn -> return (`Exn exn))

let test_empty_body () =
  Body.is_empty (`Stream (Lwt_stream.of_list [])) >|= fun res ->
  assert_equal true res

let test_non_empty_stream () =
  Body.is_empty (`Stream (Lwt_stream.of_list [ "foo"; "bar" ])) >|= fun res ->
  assert_equal false res

let test_stream_with_leading_empty_strings () =
  let s = Lwt_stream.of_list [ ""; ""; "foo"; ""; "bar" ] in
  Body.is_empty (`Stream s) >>= fun res ->
  assert_equal false res;
  Lwt_stream.to_list s >|= fun res ->
  assert_equal ~msg:"is_empty should consume leading spaces"
    [ "foo"; ""; "bar" ] res

let test_stream_empty_strings () =
  Body.is_empty (`Stream (Lwt_stream.of_list [ ""; ""; "" ])) >|= fun res ->
  assert_equal true res

let tests =
  [
    ("Empty stream", test_empty_body);
    ("Non empty stream", test_non_empty_stream);
    ("Stream with leading empty strings", test_stream_with_leading_empty_strings);
    ("Stream with empty strings", test_stream_empty_strings);
  ]

let test_suite =
  Lwt_list.map_s
    (fun (title, test) -> run_test test >|= fun res -> (title, res))
    tests
  >|= fun results ->
  let tests =
    ListLabels.map results ~f:(fun (title, res) ->
        title >:: fun () -> match res with `Ok -> () | `Exn exn -> raise exn)
  in
  "Cohttp_Lwt.Body" >::: tests

let _ = test_suite |> Cohttp_lwt_unix_test.run_async_tests |> Lwt_main.run

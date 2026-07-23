open Lwt
open Cohttp
open Cohttp_lwt_unix

let compute ~time ~f =
  Lwt.pick
    [
      (f () >|= fun v -> `Done v); (Lwt_unix.sleep time >|= fun () -> `Timeout);
    ]

let body =
  let get () = Client.get (Uri.of_string "https://www.reddit.com/") in
  compute ~time:0.1 ~f:get >>= function
  | `Timeout -> Lwt.fail_with "Timeout expired"
  | `Done (resp, body) ->
      let code = resp |> Response.status |> Code.code_of_status in
      Printf.printf "Response code: %d\n" code;
      Printf.printf "Headers: %s\n"
        (resp |> Response.headers |> Header.to_string);
      body |> Cohttp_lwt.Body.to_string >|= fun body ->
      Printf.printf "Body of length: %d\n" (String.length body);
      body

let () =
  let body = Lwt_main.run body in
  print_endline ("Received body\n" ^ body)

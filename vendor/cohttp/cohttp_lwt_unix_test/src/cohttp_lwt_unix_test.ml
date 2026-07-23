open Lwt
open OUnit
open Cohttp_lwt_unix

type 'a io = 'a Lwt.t
type ic = Lwt_io.input_channel
type oc = Lwt_io.output_channel
type body = Cohttp_lwt.Body.t

type response_action =
  [ `Expert of Cohttp.Response.t * (ic -> oc -> unit io)
  | `Response of Cohttp.Response.t * body ]

type spec = Request.t -> body -> response_action io
type async_test = unit -> unit Lwt.t

let response rsp = `Response rsp

let expert ?(rsp = Cohttp.Response.make ()) f _req _body =
  return (`Expert (rsp, f))

let const rsp _req _body = rsp >|= response
let response_sequence = Cohttp_test.response_sequence Lwt.fail_with
let () = Debug.activate_debug ()
let () = Logs.set_level (Some Info)

let temp_server ?port spec callback =
  let port = match port with None -> Cohttp_test.next_port () | Some p -> p in
  let server =
    Server.make_response_action ~callback:(fun _ req body -> spec req body) ()
  in
  let uri = Uri.of_string ("http://0.0.0.0:" ^ string_of_int port) in
  let server_failed, server_failed_wake = Lwt.task () in
  let server =
    Lwt.catch
      (fun () -> Server.create ~backlog:40 ~mode:(`TCP (`Port port)) server)
      (function
        | Lwt.Canceled -> Lwt.return_unit
        | x ->
            Lwt.wakeup_exn server_failed_wake x;
            Lwt.fail x)
  in
  Lwt.pick [ callback uri; server_failed ] >|= fun res ->
  Lwt.cancel server;
  res

let test_server_s ?port ?(name = "Cohttp Server Test") spec f =
  temp_server ?port spec (fun uri ->
      Logs.info (fun f -> f "Test %s running on %s" name (Uri.to_string uri));
      let tests = f uri in
      let results =
        tests
        |> Lwt_list.map_s (fun (name, test) ->
               Logs.info (fun f -> f "Running %s" name);
               let res =
                 Lwt.try_bind test
                   (fun () -> return `Ok)
                   (fun exn -> return (`Exn exn))
               in
               res >|= fun res -> (name, res))
      in
      results >|= fun results ->
      let ounit_tests =
        results
        |> List.map (fun (name, res) ->
               name >:: fun () -> match res with `Ok -> () | `Exn x -> raise x)
      in
      name >::: ounit_tests)

let run_async_tests test = test >|= OUnit.run_test_tt_main

open Base
open Async_kernel
open OUnit
open Cohttp_async

type 'a io = 'a Deferred.t
type ic = Async_unix.Reader.t
type oc = Async_unix.Writer.t
type body = Body.t

type response_action =
  [ `Expert of Cohttp.Response.t * (ic -> oc -> unit io)
  | `Response of Cohttp.Response.t * body ]

type spec = Request.t -> body -> response_action io
type async_test = unit -> unit io

let response rsp = `Response rsp

let expert ?(rsp = Cohttp.Response.make ()) f _req _body =
  return (`Expert (rsp, f))

let const rsp _req _body = rsp >>| response
let response_sequence = Cohttp_test.response_sequence failwith

let get_port =
  let port = ref 10_080 in
  fun () ->
    let v = !port in
    Int.incr port;
    v

let temp_server ?port spec callback =
  let port = match port with None -> get_port () | Some p -> p in
  let uri = Uri.of_string ("http://0.0.0.0:" ^ Int.to_string port) in
  let server =
    Server.create_expert ~on_handler_error:`Raise
      (Async.Tcp.Where_to_listen.of_port port) (fun ~body _sock req ->
        spec req body)
  in
  server >>= fun server ->
  callback uri >>= fun res ->
  Server.close server >>| fun () -> res

let test_server_s ?port ?(name = "Cohttp Server Test") spec f =
  temp_server ?port spec (fun uri ->
      Logs.info (fun m -> m "Test %s running on %s" name (Uri.to_string uri));
      let tests = f uri in
      let results =
        tests
        |> Deferred.List.map ~how:`Sequential ~f:(fun (name, test) ->
               Logs.debug (fun m -> m "Running %s" name);
               let res =
                 try_with test >>| function
                 | Ok () -> `Ok
                 | Error exn -> `Exn exn
               in
               res >>| fun res -> (name, res))
      in
      results >>| fun results ->
      let ounit_tests =
        results
        |> List.map ~f:(fun (name, res) ->
               name >:: fun () -> match res with `Ok -> () | `Exn x -> raise x)
      in
      name >::: ounit_tests)

let run_async_tests test =
  (* enable logging to stdout *)
  Fmt_tty.setup_std_outputs ();
  Logs.set_level @@ Some Logs.Debug;
  Logs.set_reporter (Logs_fmt.reporter ());
  test >>| fun a -> a |> OUnit.run_test_tt_main

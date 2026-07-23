open Base
open Async_kernel
open Async_unix

module Request = struct
  include Cohttp.Request
  include (Make (Io) : module type of Make (Io) with type t := t)
  end

module Response = struct
  include Cohttp.Response
  include (Make (Io) : module type of Make (Io) with type t := t)
  end

type ('address, 'listening_on) t = {
  server : ('address, 'listening_on) Tcp.Server.t; [@sexp.opaque]
}
[@@deriving sexp_of]

type response = Response.t * Body.t [@@deriving sexp_of]

type response_action =
  [ `Expert of Cohttp.Response.t * (Io.ic -> Io.oc -> unit Deferred.t)
  | `Response of response ]

type 'r respond_t =
  ?flush:bool ->
  ?headers:Cohttp.Header.t ->
  ?body:Body.t ->
  Cohttp.Code.status_code ->
  'r Deferred.t

let close t = Tcp.Server.close t.server
let close_finished t = Tcp.Server.close_finished t.server
let is_closed t = Tcp.Server.is_closed t.server
let listening_on t = Tcp.Server.listening_on t.server

let read_body req rd =
  match Request.has_body req with
  (* TODO maybe attempt to read body *)
  | `No | `Unknown -> (`Empty, Deferred.unit)
  | `Yes ->
      (* Create a Pipe for the body *)
      let reader = Request.make_body_reader req rd in
      let pipe = Body_raw.pipe_of_body Request.read_body_chunk reader in
      (`Pipe pipe, Pipe.closed pipe)

let collect_errors writer ~f =
  let monitor = Writer.monitor writer in
  (* don't propagate errors up, we handle them here *)
  Monitor.detach_and_get_error_stream monitor |> (ignore : exn Stream.t -> unit);
  choose
    [
      choice (Monitor.get_next_error monitor) (fun e ->
          Error (Exn.Reraised ("Cohttp_async.Server.collect_errors", e)));
      choice (try_with ~name:"Cohttp_async.Server.collect_errors" f) Fn.id;
    ]

let handle_client handle_request sock rd wr =
  collect_errors wr ~f:(fun () ->
      let last_body_pipe_drained = ref Deferred.unit in
      let requests_pipe =
        Reader.read_all rd (fun rd ->
            !last_body_pipe_drained >>= fun () ->
            (* [`Expert] responses may close the [Reader.t] *)
            if Reader.is_closed rd then return `Eof
            else
              Request.read rd >>= function
              | `Eof | `Invalid _ -> return `Eof
              | `Ok req -> (
                  let body, finished = read_body req rd in
                  handle_request ~body sock req >>| function
                  | `Expert (headers, io_handler) ->
                      let expert_finished = Ivar.create () in
                      last_body_pipe_drained :=
                        Deferred.all_unit
                          [ Ivar.read expert_finished; finished ];
                      `Ok (`Expert (headers, io_handler, body, expert_finished))
                  | `Response r ->
                      last_body_pipe_drained := finished;
                      `Ok (`Response (req, body, r))))
      in
      Pipe.iter ~continue_on_error:false requests_pipe ~f:(function
        | `Expert (response, io_handler, body, finished) ->
            Response.write_header response wr >>= fun () ->
            io_handler rd wr >>= fun () ->
            Body.drain body >>| fun () -> Ivar.fill_if_empty finished ()
        | `Response (req, body, (res, res_body)) ->
            (* There are scenarios if a client leaves before consuming the full response,
            we might have a reference to an async Pipe that doesn't get drained.

               Not draining or closing a pipe can lead to issues if its holding a resource like
               a file handle as those resources will never be closed, leading to a leak.

               Async writers have a promise that's fulfilled whenever they are closed,
               so we can use it to schedule a close operation on the stream to ensure that we
               don't leave a stream open if the underlying channels are closed. *)
            (match res_body with
            | `Empty | `String _ | `Strings _ -> ()
            | `Pipe stream ->
                Deferred.any_unit
                  [ Writer.close_finished wr; Writer.consumer_left wr ]
                >>> fun () -> Pipe.close_read stream);
            let keep_alive = Request.is_keep_alive req in
            let flush = Response.flush res in
            let res =
              let headers =
                Cohttp.Header.add_unless_exists
                  (Cohttp.Response.headers res)
                  "connection"
                  (if keep_alive then "keep-alive" else "close")
              in
              { res with Response.headers }
            in
            Response.write ~flush
              (Body_raw.write_body Response.write_body res_body)
              res wr
            >>= fun () ->
            Writer.(if keep_alive then flushed else close ?force_close:None) wr
            >>= fun () -> Body.drain body))
  >>= fun res ->
  Writer.close wr >>= fun () ->
  Reader.close rd >>| fun () -> Result.ok_exn res

let respond ?(flush = true) ?(headers = Cohttp.Header.init ()) ?(body = `Empty)
    status : response Deferred.t =
  let encoding = Body.transfer_encoding body in
  let resp = Response.make ~status ~flush ~encoding ~headers () in
  return (resp, body)

let respond_with_pipe ?flush ?headers ?(code = `OK) body =
  respond ?flush ?headers ~body:(`Pipe body) code

let respond_string ?flush ?headers ?(status = `OK) body =
  respond ?flush ?headers ~body:(`String body) status

let respond_with_redirect ?headers uri =
  let headers =
    Cohttp.Header.add_opt_unless_exists headers "location" (Uri.to_string uri)
  in
  respond ~flush:false ~headers `Found

(* Deprecated *)
let resolve_local_file ~docroot ~uri =
  Cohttp.Path.resolve_local_file ~docroot ~uri

let error_body_default = "<html><body><h1>404 Not Found</h1></body></html>"

let respond_with_file ?flush ?headers ?(error_body = error_body_default)
    filename =
  Monitor.try_with ~run:`Now (fun () ->
      Reader.open_file filename >>= fun rd ->
      let body = `Pipe (Reader.pipe rd) in
      let mime_type = Magic_mime.lookup filename in
      let headers =
        Cohttp.Header.add_opt_unless_exists headers "content-type" mime_type
      in
      respond ?flush ~headers ~body `OK)
  >>= function
  | Ok res -> return res
  | Error _exn -> respond_string ~status:`Not_found error_body

type mode = Conduit_async.server

let create_raw ?max_connections ?backlog ?buffer_age_limit ?(mode = `TCP)
    ~on_handler_error where_to_listen handle_request =
  Conduit_async.serve ?max_connections ?backlog ?buffer_age_limit
    ~on_handler_error mode where_to_listen
    (handle_client handle_request)
  >>| fun server -> { server }

let create_expert ?max_connections ?backlog ?buffer_age_limit ?(mode = `TCP)
    ~on_handler_error where_to_listen handle_request =
  create_raw ?max_connections ?backlog ?buffer_age_limit ~on_handler_error ~mode
    where_to_listen handle_request

let create ?max_connections ?backlog ?buffer_age_limit ?(mode = `TCP)
    ~on_handler_error where_to_listen handle_request =
  let handle_request ~body address request =
    handle_request ~body address request >>| fun r -> `Response r
  in
  create_raw ?max_connections ?backlog ?buffer_age_limit ~on_handler_error ~mode
    where_to_listen handle_request

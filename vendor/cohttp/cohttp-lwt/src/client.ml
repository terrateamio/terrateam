open Lwt.Infix
module Header = Cohttp.Header

module Make (IO : S.IO) (Net : S.Net with module IO = IO) = struct
  module IO = IO
  module Response = Make.Response (IO)
  module Request = Make.Request (IO)

  let src = Logs.Src.create "cohttp.lwt.client" ~doc:"Cohttp Lwt client"

  module Log = (val Logs.src_log src : Logs.LOG)

  type ctx = Net.ctx

  let read_body ~closefn ic res =
    match Response.has_body res with
    | `Yes | `Unknown ->
        let reader = Response.make_body_reader res ic in
        let stream = Body.create_stream Response.read_body_chunk reader in
        let body = Body.of_stream stream in
        let closed = ref false in
        (* Lwt.on_success registers a callback in the stream.
         * The GC will still be able to collect stream. *)
        Lwt.on_success (Lwt_stream.closed stream) (fun () ->
            closed := true;
            closefn ());
        (* finalise could run in a thread different from the lwt main thread.
         * You may therefore not call into Lwt from a finaliser. *)
        Gc.finalise_last
          (fun () ->
            if not !closed then
              Log.warn (fun m ->
                  m
                    "Body not consumed, leaking stream! Refer to \
                     https://github.com/mirage/ocaml-cohttp/issues/730 for \
                     additional details"))
          stream;
        body
    | `No ->
        closefn ();
        `Empty

  let is_meth_chunked = function
    | `HEAD -> false
    | `GET -> false
    | `DELETE -> false
    | _ -> true

  let call ?(ctx = Net.default_ctx) ?headers ?(body = `Empty) ?chunked meth uri
      =
    let headers = match headers with None -> Header.init () | Some h -> h in
    Net.connect_uri ~ctx uri >>= fun (_conn, ic, oc) ->
    let closefn () = Net.close ic oc in
    let chunked =
      match chunked with None -> is_meth_chunked meth | Some v -> v
    in
    let sent =
      match chunked with
      | true ->
          let req = Request.make_for_client ~headers ~chunked meth uri in
          Request.write
            (fun writer -> Body.write_body (Request.write_body writer) body)
            req oc
      | false ->
          (* If chunked is not allowed, then obtain the body length and
             insert header *)
          Body.length body >>= fun (body_length, buf) ->
          let req =
            Request.make_for_client ~headers ~chunked ~body_length meth uri
          in
          Request.write
            (fun writer -> Body.write_body (Request.write_body writer) buf)
            req oc
    in
    sent >>= fun () ->
    (Response.read ic >>= function
     | `Invalid reason ->
         Lwt.fail (Failure ("Failed to read response: " ^ reason))
     | `Eof -> Lwt.fail (Failure "Server closed connection prematurely.")
     | `Ok res -> (
         match meth with
         | `HEAD ->
             closefn ();
             Lwt.return (res, `Empty)
         | _ ->
             let body = read_body ~closefn ic res in
             Lwt.return (res, body)))
    |> fun t ->
    Lwt.on_cancel t closefn;
    Lwt.on_failure t (fun _exn -> closefn ());
    t

  (* The HEAD should not have a response body *)
  let head ?ctx ?headers uri = call ?ctx ?headers `HEAD uri >|= fst
  let get ?ctx ?headers uri = call ?ctx ?headers `GET uri

  let delete ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `DELETE uri

  let post ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `POST uri

  let put ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `PUT uri

  let patch ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `PATCH uri

  let post_form ?ctx ?headers ~params uri =
    let headers =
      Header.add_opt_unless_exists headers "content-type"
        "application/x-www-form-urlencoded"
    in
    let body = Body.of_string (Uri.encoded_of_query params) in
    post ?ctx ~chunked:false ~headers ~body uri

  let callv ?(ctx = Net.default_ctx) uri reqs =
    Net.connect_uri ~ctx uri >>= fun (_conn, ic, oc) ->
    (* Serialise the requests out to the wire *)
    let meth_stream =
      Lwt_stream.map_s
        (fun (req, body) ->
          Request.write
            (fun writer -> Body.write_body (Request.write_body writer) body)
            req oc
          >>= fun () -> Lwt.return (Request.meth req))
        reqs
    in
    (* Read the responses. For each response, ensure that the previous
       response has consumed the body before continuing to the next
       response because HTTP/1.1-pipelining cannot be interleaved. *)
    let read_m = Lwt_mutex.create () in
    let closefn () = Lwt_mutex.unlock read_m in
    let resps =
      Lwt_stream.map_s
        (fun meth ->
          Lwt_mutex.with_lock read_m (fun () ->
              (Response.read ic >>= function
               | `Invalid reason ->
                   Lwt.fail (Failure ("Failed to read response: " ^ reason))
               | `Eof ->
                   Lwt.fail (Failure "Server closed connection prematurely.")
               | `Ok res -> (
                   match meth with
                   | `HEAD ->
                       closefn ();
                       Lwt.return (res, `Empty)
                   | _ ->
                       let body = read_body ~closefn ic res in
                       Lwt.return (res, body)))
              |> fun t ->
              Lwt.on_cancel t closefn;
              Lwt.on_failure t (fun _exn -> closefn ());
              t))
        meth_stream
    in
    Lwt.on_success (Lwt_stream.closed resps) (fun () -> Net.close ic oc);
    Lwt.return resps
end

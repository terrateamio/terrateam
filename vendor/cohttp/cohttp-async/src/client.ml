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

module Net = struct
  let lookup uri =
    let host = Uri.host_with_default ~default:"localhost" uri in
    match Uri_services.tcp_port_of_uri ~default:"http" uri with
    | None ->
        Deferred.Or_error.error_string
          "Net.lookup: failed to get TCP port form Uri"
    | Some port -> (
        let open Unix in
        Addr_info.get ~host
          [ Addr_info.AI_FAMILY PF_INET; Addr_info.AI_SOCKTYPE SOCK_STREAM ]
        >>| function
        | { Addr_info.ai_addr = ADDR_INET (addr, _); _ } :: _ ->
            Or_error.return (host, Ipaddr_unix.of_inet_addr addr, port)
        | _ -> Or_error.error "Failed to resolve Uri" uri Uri_sexp.sexp_of_t)

  let connect_uri ?interrupt ?ssl_config uri =
    (match Uri.scheme uri with
    | Some "httpunix" ->
        let host = Uri.host_with_default ~default:"localhost" uri in
        return @@ `Unix_domain_socket host
    | _ -> (
        lookup uri |> Deferred.Or_error.ok_exn >>= fun (host, addr, port) ->
        return
        @@
        match (Uri.scheme uri, ssl_config) with
        | Some "https", Some config -> `OpenSSL (addr, port, config)
        | Some "https", None ->
            let config = Conduit_async.V2.Ssl.Config.create ~hostname:host () in
            `OpenSSL (addr, port, config)
        | _ -> `TCP (addr, port)))
    >>= fun mode -> Conduit_async.V2.connect ?interrupt mode
end

let read_response ic =
  Response.read ic >>| function
  | `Eof -> failwith "Connection closed by remote host"
  | `Invalid reason -> failwith reason
  | `Ok res -> (
      match Response.has_body res with
      | `Yes | `Unknown ->
          (* Build a response pipe for the body *)
          let reader = Response.make_body_reader res ic in
          let pipe = Body_raw.pipe_of_body Response.read_body_chunk reader in
          (res, pipe)
      | `No ->
          let pipe = Pipe.of_list [] in
          (res, pipe))

let request ?interrupt ?ssl_config ?uri ?(body = `Empty) req =
  (* Connect to the remote side *)
  let uri = match uri with Some t -> t | None -> Request.uri req in
  Net.connect_uri ?interrupt ?ssl_config uri >>= fun (ic, oc) ->
  try_with (fun () ->
      Request.write
        (fun writer -> Body_raw.write_body Request.write_body body writer)
        req oc
      >>= fun () ->
      read_response ic >>| fun (resp, body) ->
      don't_wait_for
        ( Pipe.closed body >>= fun () ->
          Deferred.all_unit [ Reader.close ic; Writer.close oc ] );
      (resp, `Pipe body))
  >>= function
  | Ok res -> return res
  | Error e ->
      don't_wait_for (Reader.close ic);
      don't_wait_for (Writer.close oc);
      raise e

module Connection = struct
  type t' = { ic : Reader.t; oc : Writer.t }

  (* we can't send concurrent requests over HTTP/1 *)
  type t = t' Sequencer.t

  let connect ?interrupt ?ssl_config uri =
    Net.connect_uri ?interrupt ?ssl_config uri >>| fun (ic, oc) ->
    let t = { ic; oc } |> Sequencer.create ~continue_on_error:false in
    Throttle.at_kill t (fun { ic; oc } ->
        Deferred.both (Writer.close oc) (Reader.close ic) >>| fun ((), ()) -> ());
    Deferred.any [ Writer.consumer_left oc; Reader.close_finished ic ]
    >>| (fun () -> Throttle.kill t)
    |> don't_wait_for;
    t

  let close t =
    Throttle.kill t;
    Throttle.cleaned t

  let is_closed t = Throttle.is_dead t

  let request ?(body = Body.empty) t req =
    let res = Ivar.create () in
    Throttle.enqueue t (fun { ic; oc } ->
        Request.write
          (fun writer -> Body_raw.write_body Request.write_body body writer)
          req oc
        >>= fun () ->
        read_response ic >>= fun (resp, body) ->
        Ivar.fill res (resp, `Pipe body);
        (* block starting any more requests until the consumer has finished reading this request *)
        Pipe.closed body)
    |> don't_wait_for;
    Ivar.read res
end

let callv ?interrupt ?ssl_config uri reqs =
  Connection.connect ?interrupt ?ssl_config uri >>| fun connection ->
  let responses =
    Pipe.map' ~max_queue_length:1 reqs ~f:(fun reqs ->
        Deferred.Queue.map ~how:`Sequential reqs ~f:(fun (req, body) ->
            Connection.request ~body connection req))
  in
  Pipe.closed responses
  >>= (fun () -> Connection.close connection)
  |> don't_wait_for;
  responses

let call ?interrupt ?ssl_config ?headers ?(chunked = false) ?(body = `Empty)
    meth uri =
  (* Create a request, then make the request. Figure out an appropriate
     transfer encoding *)
  (match chunked with
  | false ->
      Body_raw.disable_chunked_encoding body >>| fun (body, body_length) ->
      (Request.make_for_client ?headers ~chunked ~body_length meth uri, body)
  | true -> (
      Body.is_empty body >>| function
      | true ->
          (* Don't used chunked encoding with an empty body *)
          ( Request.make_for_client ?headers ~chunked:false ~body_length:0L meth
              uri,
            body )
      | false ->
          (* Use chunked encoding if there is a body *)
          (Request.make_for_client ?headers ~chunked:true meth uri, body)))
  >>= fun (req, body) -> request ?interrupt ?ssl_config ~body ~uri req

let get ?interrupt ?ssl_config ?headers uri =
  call ?interrupt ?ssl_config ?headers ~chunked:false `GET uri

let head ?interrupt ?ssl_config ?headers uri =
  call ?interrupt ?ssl_config ?headers ~chunked:false `HEAD uri
  >>| fun (res, body) ->
  (match body with `Pipe p -> Pipe.close_read p | _ -> ());
  res

let post ?interrupt ?ssl_config ?headers ?(chunked = false) ?body uri =
  call ?interrupt ?ssl_config ?headers ~chunked ?body `POST uri

let post_form ?interrupt ?ssl_config ?headers ~params uri =
  let headers =
    Cohttp.Header.add_opt_unless_exists headers "content-type"
      "application/x-www-form-urlencoded"
  in
  let body = Body.of_string (Uri.encoded_of_query params) in
  post ?interrupt ?ssl_config ~headers ~chunked:false ~body uri

let put ?interrupt ?ssl_config ?headers ?(chunked = false) ?body uri =
  call ?interrupt ?ssl_config ?headers ~chunked ?body `PUT uri

let patch ?interrupt ?ssl_config ?headers ?(chunked = false) ?body uri =
  call ?interrupt ?ssl_config ?headers ~chunked ?body `PATCH uri

let delete ?interrupt ?ssl_config ?headers ?(chunked = false) ?body uri =
  call ?interrupt ?ssl_config ?headers ~chunked ?body `DELETE uri

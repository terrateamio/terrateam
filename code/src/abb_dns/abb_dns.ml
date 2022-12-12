let src = Logs.Src.create "abb.dns" ~doc:"Abb DNS"

module Logs = (val Logs.src_log src : Logs.LOG)

module Make (Abb : Abb_intf.S) = struct
  module Abb_fut_comb = Abb_future_combinators.Make (Abb.Future)

  (* Based on the Lwt implementation but without TLS support *)
  module Transport :
    Dns_client.S
      with type io_addr = [ `Plaintext of Ipaddr.t * int ]
       and type +'a io = 'a Abb.Future.t
       and type stack = unit = struct
    type io_addr = [ `Plaintext of Ipaddr.t * int ]
    type +'a io = 'a Abb.Future.t
    type stack = unit

    type t = {
      nameservers : io_addr list;
      mutable preferred_ns : io_addr option;
      timeout_ns : int64;
    }

    type context = {
      sock : Abb.Socket.udp Abb.Socket.t;
      sockaddr : Abb_intf.Socket.Sockaddr.t;
    }

    let read_file file =
      try
        let fh = open_in file in
        try
          let content = really_input_string fh (in_channel_length fh) in
          close_in_noerr fh;
          Ok content
        with _ ->
          close_in_noerr fh;
          Error (`Read_File file)
      with _ -> Error (`Open_file file)

    let bind = Abb.Future.bind
    let lift = Abb.Future.return

    let create ?(nameservers : (Dns.proto * io_addr list) option) ~timeout stack =
      match nameservers with
      | Some (`Udp, nameservers) -> { nameservers; preferred_ns = None; timeout_ns = timeout }
      | Some (`Tcp, _) -> invalid_arg "tcp not supported"
      | None -> (
          Logs.debug (fun m -> m "DNS : READ_RESOLV_CONF");
          let nameservers =
            let open CCResult.Infix in
            read_file "/etc/resolv.conf"
            >>= fun content ->
            Dns_resolvconf.parse content
            >>= fun nameservers ->
            Ok (CCList.map (fun (`Nameserver ip) -> `Plaintext (ip, 53)) nameservers)
          in
          match nameservers with
          | Ok nameservers ->
              List.iter
                (fun (`Plaintext (ip, port)) ->
                  Logs.debug (fun m -> m "DNS : NAMESERVER : %s : %d" (Ipaddr.to_string ip) port))
                nameservers;
              { nameservers; preferred_ns = None; timeout_ns = timeout }
          | Error err ->
              (match err with
              | `Msg msg -> Logs.err (fun m -> m "DNS : RESOLV_CONF : %s" msg)
              | `Open_file msg -> Logs.err (fun m -> m "DNS : RESOLV_CONF_OPEN_FILE : %s" msg)
              | `Read_File msg -> Logs.err (fun m -> m "DNS : RESOLV_CONF_READ_FILE : %s" msg));
              let nameservers =
                CCList.map (fun ip -> `Plaintext (ip, 53)) Dns_client.default_resolvers
              in
              { nameservers; preferred_ns = None; timeout_ns = timeout })

    let nameservers t = (`Udp, t.nameservers)
    let rng = Mirage_crypto_rng.generate ?g:None
    let clock = Mtime_clock.elapsed_ns

    let rec connect_to_ns t errors = function
      | [] -> Abb.Future.return (Error errors)
      | `Plaintext (addr, port) :: nameservers -> (
          let domain, addr =
            match addr with
            | Ipaddr.V4 addr ->
                (Abb_intf.Socket.Domain.Inet4, Unix.inet_addr_of_string (Ipaddr.V4.to_string addr))
            | Ipaddr.V6 addr ->
                (Abb_intf.Socket.Domain.Inet6, Unix.inet_addr_of_string (Ipaddr.V6.to_string addr))
          in
          match Abb.Socket.Udp.create ~domain with
          | Ok sock -> Abb.Future.return (Ok (sock, Abb_intf.Socket.Sockaddr.(Inet { addr; port })))
          | Error (#Abb_intf.Errors.sock_create as err) ->
              connect_to_ns t (Abb_intf.Errors.show_sock_create err :: errors) nameservers)

    let connect t =
      let open Abb.Future.Infix_monad in
      let nameservers =
        match t.preferred_ns with
        | Some ns -> ns :: t.nameservers
        | None -> t.nameservers
      in
      Abb_fut_comb.timeout
        ~timeout:(Abb.Sys.sleep (Duration.to_f t.timeout_ns))
        (connect_to_ns t [] nameservers)
      >>= function
      | `Ok (Ok (sock, sockaddr)) -> Abb.Future.return (Ok (`Udp, { sock; sockaddr }))
      | `Ok (Error errors) -> Abb.Future.return (Error (`Msg (CCString.concat "," errors)))
      | `Timeout -> Abb.Future.return (Error (`Msg "Timeout"))

    let send_recv ctx data =
      let open Abb.Future.Infix_monad in
      Abb.Socket.sendto
        ctx.sock
        ~bufs:
          Abb_intf.Write_buf.[ { buf = Cstruct.to_bytes data; pos = 0; len = Cstruct.length data } ]
        ctx.sockaddr
      >>= function
      | Ok n when n = Cstruct.length data -> (
          let buf = Bytes.create (64 * 1024) in
          Abb.Socket.recvfrom ctx.sock ~buf ~pos:0 ~len:(Bytes.length buf)
          >>= function
          | Ok (n, _) ->
              let data = Cstruct.of_bytes ~len:n buf in
              Abb.Future.return (Ok data)
          | Error (#Abb_intf.Errors.recvfrom as err) ->
              Abb.Future.return (Error (`Msg (Abb_intf.Errors.show_recvfrom err))))
      | Ok _ -> Abb.Future.return (Error (`Msg "Failed to write whole query"))
      | Error (#Abb_intf.Errors.sendto as err) ->
          Abb.Future.return (Error (`Msg (Abb_intf.Errors.show_sendto err)))

    let close ctx = Abb_fut_comb.ignore (Abb.Socket.close ctx.sock)
  end

  include Dns_client.Make (Transport)

  let () = Mirage_crypto_rng_unix.initialize ()
end

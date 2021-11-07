module Make (Abb : Abb_intf.S) = struct
  module Abb_fut_comb = Abb_future_combinators.Make (Abb.Future)
  module Abb_buffered = Abb_io_buffered.Make (Abb.Future)
  module Of = Abb_io_buffered.Of (Abb)

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
      conn_w : Abb_buffered.writer Abb_buffered.t;
      conn_r : Abb_buffered.reader Abb_buffered.t;
      timeout_ns : int64;
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
        | Some (`Udp, _)           -> invalid_arg "UDP not supported"
        | Some (`Tcp, nameservers) -> { nameservers; preferred_ns = None; timeout_ns = timeout }
        | None                     -> (
            let nameservers =
              let open CCResult.Infix in
              read_file "/etc/resolve.conf"
              >>= fun content ->
              Dns_resolvconf.parse content
              >>= fun nameservers ->
              Ok (CCList.map (fun (`Nameserver ip) -> `Plaintext (ip, 53)) nameservers)
            in
            match nameservers with
              | Ok nameservers -> { nameservers; preferred_ns = None; timeout_ns = timeout }
              | Error _        ->
                  let nameservers =
                    CCList.map (fun ip -> `Plaintext (ip, 53)) Dns_client.default_resolvers
                  in
                  { nameservers; preferred_ns = None; timeout_ns = timeout })

    let nameservers t = (`Tcp, t.nameservers)

    let rng = Mirage_crypto_rng.generate ?g:None

    let clock = Mtime_clock.elapsed_ns

    let rec connect_to_ns t errors = function
      | [] -> Abb.Future.return (Error errors)
      | (`Plaintext (addr, port) as ns) :: nameservers -> (
          let (domain, addr) =
            match addr with
              | Ipaddr.V4 addr ->
                  (Abb_intf.Socket.Domain.Inet4, Unix.inet_addr_of_string (Ipaddr.V4.to_string addr))
              | Ipaddr.V6 addr ->
                  (Abb_intf.Socket.Domain.Inet6, Unix.inet_addr_of_string (Ipaddr.V6.to_string addr))
          in
          match Abb.Socket.Tcp.create ~domain with
            | Ok sock -> (
                let open Abb.Future.Infix_monad in
                Abb.Socket.Tcp.connect sock Abb_intf.Socket.Sockaddr.(Inet { addr; port })
                >>= function
                | Ok () ->
                    t.preferred_ns <- Some ns;
                    Abb.Future.return (Ok sock)
                | Error (#Abb_intf.Errors.tcp_sock_connect as err) ->
                    connect_to_ns
                      t
                      (Abb_intf.Errors.show_tcp_sock_connect err :: errors)
                      nameservers)
            | Error (#Abb_intf.Errors.sock_create as err) ->
                connect_to_ns t (Abb_intf.Errors.show_sock_create err :: errors) nameservers)

    let connect t =
      let open Abb.Future.Infix_monad in
      let nameservers =
        match t.preferred_ns with
          | Some ns -> ns :: t.nameservers
          | None    -> t.nameservers
      in
      Abb_fut_comb.timeout
        ~timeout:(Abb.Sys.sleep (Duration.to_f t.timeout_ns))
        (connect_to_ns t [] nameservers)
      >>= function
      | `Ok (Ok conn)      ->
          let (conn_r, conn_w) = Of.of_tcp_socket conn in
          Abb.Future.return (Ok { conn_w; conn_r; timeout_ns = t.timeout_ns })
      | `Ok (Error errors) -> Abb.Future.return (Error (`Msg (CCString.concat "," errors)))
      | `Timeout           -> Abb.Future.return (Error (`Msg "Timeout"))

    let send ctx data =
      let write =
        let open Abb_fut_comb.Infix_result_monad in
        Abb_buffered.write
          ctx.conn_w
          ~bufs:
            Abb_intf.Write_buf.
              [ { buf = Cstruct.to_bytes data; pos = 0; len = Cstruct.length data } ]
        >>= fun _ -> Abb_buffered.flushed ctx.conn_w
      in
      let open Abb.Future.Infix_monad in
      write
      >>= function
      | Ok _ -> Abb.Future.return (Ok ())
      | Error (#Abb_io_buffered.write_err as err) ->
          Abb.Future.return (Error (`Msg (Abb_io_buffered.show_write_err err)))

    let recv ctx =
      let open Abb.Future.Infix_monad in
      let buf = Bytes.create 1024 in
      Abb_buffered.read ctx.conn_r ~buf ~pos:0 ~len:(Bytes.length buf)
      >>= function
      | Ok n ->
          let data = Cstruct.of_bytes ~len:n buf in
          Abb.Future.return (Ok data)
      | Error (#Abb_io_buffered.read_err as err) ->
          Abb.Future.return (Error (`Msg (Abb_io_buffered.show_read_err err)))

    let close ctx = Abb_fut_comb.ignore (Abb_buffered.close ctx.conn_r)
  end

  include Dns_client.Make (Transport)

  let () = Mirage_crypto_rng_unix.initialize ()
end

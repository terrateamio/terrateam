type connect_err = [ `He_connect_err ] [@@deriving show]

module Make (Abb : Abb_intf.S) = struct
  module Abb_fut_comb = Abb_future_combinators.Make (Abb.Future)

  let try_connect ip port =
    let tcp =
      let domain =
        match ip with
        | Ipaddr.V4 _ -> Abb_intf.Socket.Domain.Inet4
        | Ipaddr.V6 _ -> Abb_intf.Socket.Domain.Inet6
      in
      Abb.Socket.Tcp.create ~domain
    in
    let open Abb_fut_comb.Infix_result_monad in
    Abb.Future.return tcp
    >>= fun tcp ->
    Abb_fut_comb.on_failure
      (fun () ->
        let open Abb.Future.Infix_monad in
        let addr =
          Abb_intf.Socket.Sockaddr.(
            Inet { addr = Unix.inet_addr_of_string (Ipaddr.to_string ip); port })
        in
        Abb.Socket.Tcp.connect tcp addr
        >>= function
        | Ok () -> Abb.Future.return (Ok tcp)
        | Error _ as err ->
            Abb_fut_comb.ignore (Abb.Socket.close tcp) >>= fun () -> Abb.Future.return err)
      ~failure:(fun () -> Abb_fut_comb.ignore (Abb.Socket.close tcp))

  let act =
    let open Abb.Future.Infix_monad in
    function
    | Happy_eyeballs.Resolve_a host -> (
        Abb.Socket.getaddrinfo
          ~hints:[ Abb_intf.Socket.(Addrinfo_hints.Family Domain.Inet4) ]
          (Abb_intf.Socket.Addrinfo_query.Host (Domain_name.to_string host))
        >>| function
        | Ok [] | Error _ -> `Event (Happy_eyeballs.Resolved_a_failed (host, ""))
        | Ok addrs -> (
            addrs
            |> CCList.flat_map (function
                   | Abb_intf.Socket.(Addrinfo.{ addr = Sockaddr.(Inet { addr; _ }); _ }) ->
                       CCOption.to_list
                         (CCOption.of_result (Ipaddr.V4.of_string (Unix.string_of_inet_addr addr)))
                   | _ -> assert false)
            |> Ipaddr.V4.Set.of_list
            |> function
            | set when Ipaddr.V4.Set.is_empty set ->
                `Event (Happy_eyeballs.Resolved_a_failed (host, "No IPv6 addresses found"))
            | set -> `Event (Happy_eyeballs.Resolved_a (host, set))))
    | Happy_eyeballs.Resolve_aaaa host -> (
        Abb.Socket.getaddrinfo
          ~hints:[ Abb_intf.Socket.(Addrinfo_hints.Family Domain.Inet6) ]
          (Abb_intf.Socket.Addrinfo_query.Host (Domain_name.to_string host))
        >>| function
        | Ok [] | Error _ -> `Event (Happy_eyeballs.Resolved_aaaa_failed (host, ""))
        | Ok addrs -> (
            addrs
            |> CCList.flat_map (function
                   | Abb_intf.Socket.(Addrinfo.{ addr = Sockaddr.(Inet { addr; _ }); _ }) ->
                       CCOption.to_list
                         (CCOption.of_result (Ipaddr.V6.of_string (Unix.string_of_inet_addr addr)))
                   | _ -> assert false)
            |> Ipaddr.V6.Set.of_list
            |> function
            | set when Ipaddr.V6.Set.is_empty set ->
                `Event (Happy_eyeballs.Resolved_aaaa_failed (host, "No IPv6 addresses found"))
            | set -> `Event (Happy_eyeballs.Resolved_aaaa (host, set))))
    | Happy_eyeballs.Connect (host, id, (ip, port)) -> (
        try_connect ip port
        >>= function
        | Ok tcp -> Abb.Future.return (`Ok ((ip, port), tcp))
        | Error _ ->
            Abb.Future.return (`Event (Happy_eyeballs.Connection_failed (host, id, (ip, port), "")))
        )
    | Happy_eyeballs.Connect_failed (_, _, _) -> Abb.Future.return `He_connect_err
    | Happy_eyeballs.Connect_cancelled (_, _) -> Abb.Future.return `He_connect_err

  (* Each action is a future whose result is the application of {!act}.  We wait
     for the first response, and depending on what that is, we continue on
     evaluating the rest of the futures or abort them. *)
  let rec do_step he timer_duration actions =
    let open Abb.Future.Infix_monad in
    Abb_fut_comb.firstl actions
    >>= function
    | `He_connect_err, futs ->
        Abb_fut_comb.List.iter_par ~f:Abb.Future.abort futs >>| fun () -> Error `He_connect_err
    | `Event ev, futs ->
        Abb.Sys.monotonic ()
        >>= fun ts ->
        let ts = Duration.(to_us_64 (of_f ts)) in
        let he, actions' = Happy_eyeballs.event he ts ev in
        let actions' = CCList.map act actions' in
        do_step he timer_duration (actions' @ futs)
    | `Ok ret, futs ->
        Abb_fut_comb.List.iter_par ~f:Abb.Future.abort futs >>= fun () -> Abb.Future.return (Ok ret)
    | `Timeout, futs -> (
        Abb.Sys.monotonic ()
        >>= fun ts ->
        let ts = Duration.(to_us_64 (of_f ts)) in
        let he, cont, actions = Happy_eyeballs.timer he ts in
        match cont with
        | `Suspend -> Abb.Future.return (Error `He_connect_err)
        | `Act ->
            let timer = Abb.Sys.sleep (Duration.to_f timer_duration) >>| fun () -> `Timeout in
            do_step he timer_duration (timer :: futs))

  let run he timer_duration actions =
    let timer =
      let open Abb.Future.Infix_monad in
      Abb.Sys.sleep (Duration.to_f timer_duration) >>| fun () -> `Timeout
    in
    let actions = CCList.map act actions in
    do_step he timer_duration (timer :: actions)

  let connect' he_connect =
    let open Abb.Future.Infix_monad in
    Abb.Sys.monotonic ()
    >>= fun ts ->
    let ts = Duration.(to_us_64 (of_f ts)) in
    let he = Happy_eyeballs.create ts in
    let _, id = Happy_eyeballs.Waiter_map.register "" Happy_eyeballs.Waiter_map.empty in
    let he, actions = he_connect he ts id in
    run he (Duration.of_ms 10) actions

  let connect host ports =
    (* Happy_eyeballs has a different approach depending on if we're connecting
       to an IP or a hostname.  We're using [dummy_id] here because each
       instance of happy eyeballs is created per lookup, so there will never
       have more than one lookup happening, therefore we don't need to
       distinguish them with id's. *)
    match Ipaddr.of_string host with
    | Ok ip ->
        connect' (fun he ts id ->
            Happy_eyeballs.connect_ip he ts ~id (List.map (fun p -> (ip, p)) ports))
    | Error _ -> (
        match Domain_name.of_string host with
        | Ok dn ->
            connect' (fun he ts id ->
                Happy_eyeballs.connect he ts ~id (Domain_name.host_exn dn) ports)
        | Error _ -> failwith "nyi")
end

module Abb_dns = Abb_dns.Make (Abb)

let () =
  let run () =
    let open Abb.Future.Infix_monad in
    let dns = Abb_dns.create () in
    (match Abb_dns.nameservers dns with
      | (`Tcp, nameservers) ->
          CCList.iter
            (function
              | `Plaintext (addr, port) ->
                  Printf.printf "addr = %s port = %d\n" (Ipaddr.to_string addr) port)
            nameservers
      | _                   -> ());
    (* Abb_dns.getaddrinfo dns Dns.Rr_map.Srv Domain_name.(of_string_exn "_http._tcp.mxtoolbox.com") *)
    Abb_dns.gethostbyname dns Domain_name.(host_exn (of_string_exn "acsl.se."))
    >>= function
    (* | Ok (ttl, srv) ->
     *     let records = CCSeq.to_list (Dns.Rr_map.Srv_set.to_seq srv) in
     *     CCList.iter
     *       (fun srv ->
     *         Printf.printf
     *           "Name = %s Port = %d Priority = %d Weight = %d\n"
     *           (Domain_name.to_string srv.Dns.Srv.target)
     *           srv.Dns.Srv.port
     *           srv.Dns.Srv.priority
     *           srv.Dns.Srv.weight)
     *       records;
     *     Abb.Future.return () *)
    | Ok ip ->
        print_endline (Ipaddr.V4.to_string ip);
        Abb.Future.return ()
    | Error (`Msg err) ->
        print_endline "failed";
        print_endline err;
        Abb.Future.return ()
    | Error (`No_domain _) | Error (`No_data _) ->
        print_endline "err";
        Abb.Future.return ()
  in
  ignore (Abb.Scheduler.run_with_state run)

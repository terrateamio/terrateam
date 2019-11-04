module Unix = UnixLabels

module Make (Abb : Abb_intf.S) = struct
  module Oth_abb = Oth_abb.Make (Abb)

  let getaddrinfo_test =
    Oth_abb.test ~desc:"Evaluate localhost" ~name:"Getaddrinfo test" (fun () ->
        let open Abb.Future.Infix_monad in
        Abb.Socket.getaddrinfo
          ~hints:
            Abb_intf.Socket.
              [ Addrinfo_hints.Socket_type Socket_type.Stream; Addrinfo_hints.Family Domain.Inet4 ]
          Abb_intf.Socket.Addrinfo_query.(Host "localhost")
        >>= function
        | Ok r    ->
            List.iter
              (fun ai ->
                match ai.Abb_intf.Socket.Addrinfo.addr with
                  | Abb_intf.Socket.Sockaddr.Unix _ -> assert false
                  | Abb_intf.Socket.Sockaddr.Inet inet -> ())
              r;
            Abb.Future.return ()
        | Error _ -> failwith "getaddrinfo failed")

  let test = Oth_abb.serial [ getaddrinfo_test ]
end

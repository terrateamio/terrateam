module T_dns = Abb_dns.Make (Abb)

type t = T_dns.t

let create () = T_dns.create ()

let srv t installation_id =
  let open Abb.Future.Infix_monad in
  let host = Printf.sprintf "atlantis-%Ld.terrateam.local" installation_id in
  match Domain_name.of_string host with
    | Ok domain -> (
        T_dns.get_resource_record t Dns.Rr_map.Srv domain
        >>= function
        | Ok (_, srv) -> (
            match Dns.Rr_map.Srv_set.min_elt_opt srv with
              | Some record ->
                  Abb.Future.return
                    (Ok (Domain_name.to_string record.Dns.Srv.target, record.Dns.Srv.port))
              | None        -> Abb.Future.return (Error `Dns_error))
        | Error _     -> Abb.Future.return (Error `Dns_error))
    | Error _   -> Abb.Future.return (Error `Dns_error)

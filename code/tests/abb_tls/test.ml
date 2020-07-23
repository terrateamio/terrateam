(* This is a really simple test that calls an external site so this could break
   for no good reason. *)

module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Http = Cohttp_abb.Make (Abb)
module Buffered = Abb_io_buffered.Make (Abb.Future)
module Buffered_of = Abb_io_buffered.Of (Abb)
module Abb_tls = Abb_tls.Make (Abb)

let google =
  Oth_abb.test ~desc:"HTTPS request to https://google.com" ~name:"HTTPS Google" (fun () ->
      let open Abb.Future.Infix_monad in
      let uri = Uri.of_string "https://google.com/" in
      let tls_config = Otls.Tls_config.create () in
      Otls.Tls_config.insecure_noverifycert tls_config;
      Http.Client.call ~flush:true ~tls_config `GET uri
      >>| function
      | Ok (resp, _) ->
          let status = Http.Response.status resp in
          assert (
            301 = Cohttp.Code.code_of_status status
            || 302 = Cohttp.Code.code_of_status status
            || 200 = Cohttp.Code.code_of_status status )
      | Error `E_access -> assert false
      | Error `E_address_family_not_supported -> assert false
      | Error `E_address_in_use -> assert false
      | Error `E_address_not_available -> assert false
      | Error `E_bad_file -> assert false
      | Error `E_connection_refused -> assert false
      | Error `E_connection_reset -> assert false
      | Error `E_file_table_full -> assert false
      | Error `E_host_unreachable -> assert false
      | Error `E_invalid -> assert false
      | Error `E_is_connected -> assert false
      | Error `E_network_unreachable -> assert false
      | Error `E_no_buffers -> assert false
      | Error `E_permission -> assert false
      | Error `E_protocol_not_supported -> assert false
      | Error `E_protocol_type -> assert false
      | Error `Error -> assert false
      | Error (`Invalid_scheme _) -> assert false
      | Error (`Unexpected _) -> assert false
      | Error (`Invalid _) -> assert false)

let test = Oth_abb.(to_sync_test (parallel [ google ]))

let () =
  Random.self_init ();
  Oth.run test

module Server_core = Cohttp_lwt.Make_server (Io)
include Server_core
open Lwt.Infix

let src =
  Logs.Src.create "cohttp.lwt.server" ~doc:"Cohttp Lwt Unix server module"

module Log = (val Logs.src_log src : Logs.LOG)

(* Deprecated *)
let resolve_file ~docroot ~uri = Cohttp.Path.resolve_local_file ~docroot ~uri

exception Isnt_a_file

let respond_file ?headers ~fname () =
  Lwt.catch
    (fun () ->
      (* Check this isnt a directory first *)
      ( fname |> Lwt_unix.stat >>= fun s ->
        if Unix.(s.st_kind <> S_REG) then Lwt.fail Isnt_a_file
        else Lwt.return_unit )
      >>= fun () ->
      let count = 16384 in
      Lwt_io.open_file ~buffer:(Lwt_bytes.create count) ~mode:Lwt_io.input fname
      >>= fun ic ->
      Lwt_io.length ic >>= fun len ->
      let encoding = Cohttp.Transfer.Fixed len in
      let stream =
        Lwt_stream.from (fun () ->
            Lwt.catch
              (fun () ->
                Lwt_io.read ~count ic >|= function
                | "" -> None
                | buf -> Some buf)
              (fun exn ->
                Log.warn (fun m ->
                    m "Error resolving file %s (%s)" fname
                      (Printexc.to_string exn));
                Lwt.return_none))
      in
      Lwt.on_success (Lwt_stream.closed stream) (fun () ->
          Lwt.ignore_result
          @@ Lwt.catch
               (fun () -> Lwt_io.close ic)
               (fun e ->
                 Log.warn (fun f ->
                     f "Closing channel failed: %s" (Printexc.to_string e));
                 Lwt.return_unit));
      let body = Cohttp_lwt.Body.of_stream stream in
      let mime_type = Magic_mime.lookup fname in
      let headers =
        Cohttp.Header.add_opt_unless_exists headers "content-type" mime_type
      in
      let res = Cohttp.Response.make ~status:`OK ~encoding ~headers () in
      Lwt.return (res, body))
    (function
      | Unix.Unix_error (Unix.ENOENT, _, _) | Isnt_a_file ->
          respond_not_found ()
      | exn -> Lwt.fail exn)

let log_on_exn = function
  | Unix.Unix_error (error, func, arg) ->
      Log.warn (fun m ->
          m "Client connection error %s: %s(%S)" (Unix.error_message error) func
            arg)
  | exn -> Log.err (fun m -> m "Unhandled exception: %a" Fmt.exn exn)

let create ?timeout ?backlog ?stop ?(on_exn = log_on_exn)
    ?(ctx = Net.default_ctx) ?(mode = `TCP (`Port 8080)) spec =
  Conduit_lwt_unix.serve ?backlog ?timeout ?stop ~on_exn ~ctx:ctx.Net.ctx ~mode
    (callback spec)

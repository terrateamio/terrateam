module Abb = Abb_scheduler_kqueue
module Curl = Abb_curl_easy.Make (Abb)

let get uri =
  let open Abb.Future.Infix_monad in
  Curl.get uri
  >>= function
  | Ok (resp, body) ->
      Printf.printf "%d\n" (CCString.length body);
      Abb.Future.return ()
  | Error (#Curl.request_err as err) ->
      Printf.printf "%s\n%!" (Curl.show_request_err err);
      exit 1

let main () =
  let reporter ppf =
    let report src level ~over k msgf =
      let k _ =
        over ();
        k ()
      in
      let with_stamp h tags k ppf fmt =
        (* TODO: Make this use the proper Abb time *)
        let time = Unix.gettimeofday () in
        let time_str = ISO8601.Permissive.string_of_datetime time in
        Format.kfprintf
          k
          ppf
          ("[%s] %a [%s] @[" ^^ fmt ^^ "@]@.")
          time_str
          Logs.pp_header
          (level, h)
          (Logs.Src.name src)
      in
      msgf @@ fun ?header ?tags fmt -> with_stamp header tags k ppf fmt
    in
    { Logs.report }
  in
  Logs.set_reporter (reporter Format.std_formatter);
  Logs.set_level (Some Logs.Debug);
  let rec run = function
    | [] -> Abb.Future.return ()
    | uri :: xs ->
        let open Abb.Future.Infix_monad in
        get (Uri.of_string uri) >>= fun () -> run xs
  in
  match Abb.Scheduler.run_with_state (fun () -> run (List.drop 1 (Array.to_list Sys.argv))) with
  | `Det () -> ()
  | `Aborted -> failwith "Aborted"
  | `Exn (exn, bt_opt) ->
      Printf.eprintf "Exn = %s\n" (Printexc.to_string exn);
      CCOption.iter (fun bt -> Printf.eprintf "%s\n" (Printexc.raw_backtrace_to_string bt)) bt_opt;
      raise exn

let () = main ()

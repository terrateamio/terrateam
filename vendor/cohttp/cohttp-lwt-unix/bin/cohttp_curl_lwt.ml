(*{{{ Copyright (c) 2014 Hannes Mehnert
 * Copyright (c) 2014 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
  }}}*)

open Lwt
open Cohttp
open Cohttp_lwt_unix

let src =
  Logs.Src.create "cohttp.lwt.curl" ~doc:"Cohttp Lwt curl implementation"

module Log = (val Logs.src_log src : Logs.LOG)

let client uri ofile meth' =
  Log.debug (fun d -> d "Client with URI %s" (Uri.to_string uri));
  let meth = Cohttp.Code.method_of_string meth' in
  Log.debug (fun d -> d "Client %s issued" meth');
  Client.call meth uri >>= fun (resp, body) ->
  let status = Response.status resp in
  Log.debug (fun d ->
      d "Client %s returned: %s" meth' (Code.string_of_status status));
  (* TODO follow redirects *)
  match Code.is_success (Code.code_of_status status) with
  | false ->
      prerr_endline (Code.string_of_status status);
      exit 1
  | true -> (
      Cohttp_lwt.Body.length body >>= fun (len, body) ->
      Log.debug (fun d -> d "Client body length: %Ld" len);
      Cohttp_lwt.Body.to_string body >>= fun _s ->
      let output_body c =
        Lwt_stream.iter_s (Lwt_io.fprint c) (Cohttp_lwt.Body.to_stream body)
      in
      match ofile with
      | None -> output_body Lwt_io.stdout
      | Some fname -> Lwt_io.with_file ~mode:Lwt_io.output fname output_body)

let run_client level ofile uri meth =
  if not @@ Debug.debug_active () then (
    Fmt_tty.setup_std_outputs ();
    Logs.set_level ~all:true level;
    Logs.set_reporter Debug.default_reporter);
  Lwt_main.run (client uri ofile meth)

open Cmdliner

let uri =
  let loc : Uri.t Arg.conv =
    let parse s =
      try `Ok (Uri.of_string s) with Failure _ -> `Error "unable to parse URI"
    in
    (parse, fun ppf p -> Format.fprintf ppf "%s" (Uri.to_string p))
  in
  Arg.(
    required
    & pos 0 (some loc) None
    & info [] ~docv:"URI"
        ~doc:"string of the remote address (e.g. https://google.com)")

let meth =
  let doc = "Set http method" in
  Arg.(value & opt string "GET" & info [ "X"; "request" ] ~doc)

let verb = Logs_cli.level ()

let ofile =
  let doc = "Output filename to store the URI into." in
  Arg.(value & opt (some string) None & info [ "o" ] ~docv:"FILE" ~doc)

let cmd =
  let info =
    let version = Cohttp.Conf.version in
    let doc = "retrieve a remote URI contents" in
    let man =
      [
        `S "DESCRIPTION";
        `P
          "$(tname) fetches the remote $(i,URI) and prints it to standard \
           output. The output file can also be specified with the $(b,-o) \
           option, and more verbose debugging out obtained via the $(b,-v) \
           option.";
        `S "BUGS";
        `P
          "Report them via e-mail to <mirageos-devel@lists.xenproject.org>, or \
           on the issue tracker at \
           <https://github.com/mirage/ocaml-cohttp/issues>";
        `S "SEE ALSO";
        `P "$(b,curl)(1), $(b,wget)(1)";
      ]
    in
    Cmd.info "cohttp-curl" ~version ~doc ~man
  in
  let term = Term.(const run_client $ verb $ ofile $ uri $ meth) in
  Cmd.v info term

let () = exit @@ Cmd.eval cmd

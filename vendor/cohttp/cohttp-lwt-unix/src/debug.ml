(*{{{ Copyright (c) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
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

let _debug_active = ref false
let debug_active () = !_debug_active

open Lwt.Infix

let reporter file_descr ppf =
  let ppf, flush =
    let buf = Buffer.create 0x100 in
    ( Fmt.with_buffer ~like:ppf buf,
      fun () ->
        let str = Buffer.contents buf in
        Buffer.reset buf;
        str )
  in
  let report src level ~over k msgf =
    let k _ =
      let write () =
        let buf = Bytes.unsafe_of_string (flush ()) in
        let rec go off len =
          Lwt_unix.write file_descr buf off len >>= fun len' ->
          if len' = len then Lwt.return_unit else go (off + len') (len - len')
        in
        go 0 (Bytes.length buf)
      in
      let clean () =
        over ();
        Lwt.return_unit
      in
      Lwt.async (fun () ->
          Lwt.catch
            (fun () -> Lwt.finalize write clean)
            (fun exn ->
              Logs.warn (fun m ->
                  m "Flushing error: %s." (Printexc.to_string exn));
              Lwt.return_unit));
      k ()
    in
    let with_metadata header _tags k ppf fmt =
      Format.kfprintf k ppf
        ("%a[%a]: " ^^ fmt ^^ "\n%!")
        Logs_fmt.pp_header (level, header)
        Fmt.(styled `Magenta string)
        (Logs.Src.name src)
    in
    msgf @@ fun ?header ?tags fmt -> with_metadata header tags k ppf fmt
  in
  { Logs.report }

let default_reporter = reporter Lwt_unix.stderr Fmt.stderr

let set_logger =
  lazy
    (if
     (* If no reporter has been set by the application, set default one
        that prints to stderr *)
     Logs.reporter () == Logs.nop_reporter
    then Logs.set_reporter default_reporter)

let activate_debug () =
  if not !_debug_active then (
    _debug_active := true;
    Lazy.force set_logger;
    Logs.set_level ~all:true (Some Logs.Debug);
    Logs.debug (fun f -> f "Cohttp debugging output is active"))

let () =
  try
    match Sys.getenv "COHTTP_DEBUG" with
    | "false" | "0" -> ()
    | _ -> activate_debug ()
  with Not_found -> ()

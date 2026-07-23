(*{{{ Copyright (c) 2012-2013 Anil Madhavapeddy <anil@recoil.org>
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

open Base
open Async_kernel
module Writer = Async_unix.Writer
module Reader = Async_unix.Reader
module Format = Stdlib.Format

let log_src_name = "cohttp.async.io"
let src = Logs.Src.create log_src_name ~doc:"Cohttp Async IO module"

module Log = (val Logs.src_log src : Logs.LOG)

let default_reporter () =
  let fmtr, fmtr_flush =
    let b = Buffer.create 512 in
    ( Fmt.with_buffer ~like:Fmt.stderr b,
      fun () ->
        let m = Buffer.contents b in
        Buffer.reset b;
        m )
  in
  let report src _level ~over k msgf =
    let k _ =
      if String.equal (Logs.Src.name src) log_src_name then
        Writer.write (Lazy.force Writer.stderr) (fmtr_flush ());
      over ();
      k ()
    in
    msgf @@ fun ?header:_ ?tags:_ fmt ->
    Format.kfprintf k fmtr Stdlib.("@[" ^^ fmt ^^ "@]@.")
  in
  { Logs.report }

let set_log =
  lazy
    ((* If no reporter has been set by the application, set default one
        that prints to stderr. This way a user will see logs when the debug
        flag is set without adding a reporter. *)
     if phys_equal (Logs.reporter ()) Logs.nop_reporter then
       Logs.set_level @@ Some Logs.Debug;
     Logs.set_reporter (default_reporter ()))

let check_debug norm_fn debug_fn =
  match Stdlib.Sys.getenv "COHTTP_DEBUG" with
  | _ ->
      Lazy.force set_log;
      debug_fn
  | exception Stdlib.Not_found -> norm_fn

type 'a t = 'a Deferred.t

let ( >>= ) = Deferred.( >>= )
let return = Deferred.return

type ic = Reader.t
type oc = Writer.t
type conn = unit

let read_line =
  check_debug
    (fun ic ->
      Reader.read_line ic >>| function `Ok s -> Some s | `Eof -> None)
    (fun ic ->
      Reader.read_line ic >>| function
      | `Ok s ->
          Log.debug (fun fmt -> fmt "<<< %s" s);
          Some s
      | `Eof ->
          Log.debug (fun fmt -> fmt "<<<EOF");
          None)

let read ic len =
  let buf = Bytes.create len in
  Reader.read ic ~len buf >>| function
  | `Ok len' -> Bytes.To_string.sub buf ~pos:0 ~len:len'
  | `Eof -> ""

let write =
  check_debug
    (fun oc buf ->
      Writer.write oc buf;
      return ())
    (fun oc buf ->
      Log.debug (fun fmt -> fmt "%4d >>> %s" (Unix.getpid ()) buf);
      Writer.write oc buf;
      return ())

let flush = Writer.flushed

(*
 * Copyright (c) 2012-2017 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2015 Thomas Gazagnaire <thomas@gazazagnaire.org>
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
 * %%NAME%% %%VERSION%%
 *)

module Key = Mirage_kv.Key

module HTTP (FS : Mirage_kv.RO) (S : Cohttp_lwt.S.Server) = struct
  open Lwt.Infix
  open Astring

  let failf fmt = Fmt.kstr Lwt.fail_with fmt

  let read_fs t name =
    FS.get t (Key.v name) >>= function
    | Error e -> failf "read %a" FS.pp_error e
    | Ok buf -> Lwt.return buf

  let exists t name =
    FS.exists t (Key.v name) >|= function
    | Ok (Some `Value) -> true
    | Ok (Some _ | None) -> false
    | Error e -> Fmt.failwith "exists %a" FS.pp_error e

  let dispatcher request_fn =
    let rec fn fs uri =
      match Uri.path uri with
      | ("" | "/") as path ->
          Logs.info (fun f -> f "request for '%s'" path);
          fn fs (Uri.with_path uri "index.html")
      | path when String.is_suffix ~affix:"/" path ->
          Logs.info (fun f -> f "request for '%s'" path);
          fn fs (Uri.with_path uri "index.html")
      | path ->
          Logs.info (fun f -> f "request for '%s'" path);
          Lwt.catch
            (fun () ->
              read_fs fs path >>= fun body ->
              let mime_type = Magic_mime.lookup path in
              let headers = Cohttp.Header.init_with "content-type" mime_type in
              let headers =
                match request_fn with
                | None -> headers
                | Some fn -> fn uri headers
              in
              S.respond_string ~status:`OK ~body ~headers ())
            (fun _exn ->
              let with_index = Fmt.str "%s/index.html" path in
              exists fs with_index >>= function
              | true -> fn fs (Uri.with_path uri with_index)
              | false -> S.respond_not_found ())
    in
    fn

  let start ~http_port ?request_fn fs http =
    let callback (_, cid) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string cid in
      Logs.info (fun f -> f "[%s] serving %s" cid (Uri.to_string uri));
      dispatcher request_fn fs uri
    in
    let conn_closed (_, cid) =
      let cid = Cohttp.Connection.to_string cid in
      Logs.info (fun f -> f "[%s] closing" cid)
    in
    Logs.info (fun f -> f "listening on %d/TCP" http_port);
    http (`TCP http_port) (S.make ~conn_closed ~callback ())
end

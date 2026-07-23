(*{{{ Copyright (c) 2014 Andy Ray
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

open Js_of_ocaml
module C = Cohttp
module CLB = Cohttp_lwt.Body

let ( >>= ) = Lwt.( >>= )
let ( >|= ) = Lwt.( >|= )

module type Params = sig
  val chunked_response : bool
  val chunk_size : int
  val convert_body_string : Js.js_string Js.t -> string
  val with_credentials : bool
end

let xhr_response_supported =
  (* from http://stackoverflow.com/questions/8926505/how-to-feature-detect-if-xmlhttprequest-supports-responsetype-arraybuffer *)
  let xhr = XmlHttpRequest.create () in
  let rt = xhr##.responseType in
  Js.to_string (Js.typeof rt) = "string"

let binary_string str =
  let len = String.length str in
  let a = new%js Typed_array.uint8Array len in
  for i = 0 to len - 1 do
    Typed_array.set a i (Char.code str.[i])
  done;
  a

let string_of_uint8array u8a offset len =
  String.init len (fun i -> Char.chr (Typed_array.unsafe_get u8a (offset + i)))

module String_io = Cohttp__String_io
module IO = Cohttp_lwt__String_io
module Header_io = Cohttp__Header_io.Make (IO)

module Body_builder (P : Params) = struct
  let src = Logs.Src.create "cohttp.lwt.jsoo" ~doc:"Cohttp Lwt JSOO module"

  module Log = (val Logs.src_log src : Logs.LOG)

  (* perform the body transfer in chunks from string. *)
  let chunked_body_str text =
    let body_len = text##.length in
    let pos = ref 0 in
    let chunkerizer () =
      if !pos = body_len then Lwt.return C.Transfer.Done
      else if !pos + P.chunk_size >= body_len then (
        let str = text ## (substring_toEnd !pos) in
        pos := body_len;
        Lwt.return (C.Transfer.Final_chunk (P.convert_body_string str)))
      else
        let str = text ## (substring !pos (!pos + P.chunk_size)) in
        pos := !pos + P.chunk_size;
        Lwt.return (C.Transfer.Chunk (P.convert_body_string str))
    in
    if body_len = 0 then CLB.empty
    else CLB.of_stream (CLB.create_stream chunkerizer ())

  (* perform the body transfer in chunks from arrayBuffer. *)
  let chunked_body_binary (ab : Typed_array.arrayBuffer Js.t) =
    let body_len = ab##.byteLength in
    let u8a = new%js Typed_array.uint8Array_fromBuffer ab in
    let pos = ref 0 in
    let chunkerizer () =
      if !pos = body_len then Lwt.return C.Transfer.Done
      else if !pos + P.chunk_size >= body_len then (
        let str = string_of_uint8array u8a !pos (body_len - !pos) in
        pos := body_len;
        Lwt.return (C.Transfer.Final_chunk str))
      else
        let str = string_of_uint8array u8a !pos P.chunk_size in
        pos := !pos + P.chunk_size;
        Lwt.return (C.Transfer.Chunk str)
    in
    if body_len = 0 then CLB.empty
    else CLB.of_stream (CLB.create_stream chunkerizer ())

  (* choose between chunked and direct transfer *)
  let get = function
    | `String js_str ->
        if P.chunked_response then chunked_body_str js_str
        else CLB.of_string (P.convert_body_string js_str)
    | `ArrayBuffer ab ->
        if P.chunked_response then chunked_body_binary ab
        else
          let u8a = new%js Typed_array.uint8Array_fromBuffer ab in
          CLB.of_string (string_of_uint8array u8a 0 ab##.byteLength)

  let construct_body xml =
    (* construct body *)
    let b =
      let respText () =
        Js.Opt.case xml##.responseText
          (fun () -> `String (Js.string ""))
          (fun s -> `String s)
      in
      match xhr_response_supported with
      | true when Js.Opt.return xml##.response == Js.null ->
          Log.warn (fun m -> m "XHR Response is null; using empty string");
          `String (Js.string "")
      | true ->
          Js.Opt.case
            (File.CoerceTo.arrayBuffer xml##.response)
            (fun () ->
              Log.warn (fun m ->
                  m "XHR Response is not an arrayBuffer; using responseText");
              respText ())
            (fun ab -> `ArrayBuffer ab)
      | false -> respText ()
    in
    get b
end

module Make_api (X : sig
  module Request : Cohttp.S.Request
  module Response : Cohttp.S.Response

  val call :
    ?headers:Cohttp.Header.t ->
    ?body:Cohttp_lwt.Body.t ->
    Cohttp.Code.meth ->
    Uri.t ->
    (Response.t * Cohttp_lwt.Body.t) Lwt.t
end) =
struct
  module Request = X.Request
  module Response = X.Response

  type ctx = unit

  let call ?ctx:_ ?headers ?body ?chunked:_ meth uri =
    X.call ?headers ?body meth uri

  (* The HEAD should not have a response body *)
  let head ?ctx ?headers uri =
    let open Lwt in
    call ?ctx ?headers ~chunked:false `HEAD uri >|= fst

  let get ?ctx ?headers uri = call ?ctx ?headers ~chunked:false `GET uri

  let delete ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `DELETE uri

  let post ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `POST uri

  let put ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `PUT uri

  let patch ?ctx ?body ?chunked ?headers uri =
    call ?ctx ?headers ?body ?chunked `PATCH uri

  let post_form ?ctx ?headers ~params uri =
    let headers =
      C.Header.add_opt headers "content-type"
        "application/x-www-form-urlencoded"
    in
    let body = Cohttp_lwt.Body.of_string (Uri.encoded_of_query params) in
    post ?ctx ~chunked:false ~headers ~body uri

  (* No implementation (can it be done?).  What should the failure exception be? *)
  exception Cohttp_lwt_xhr_callv_not_implemented

  let callv ?ctx:_ _uri _reqs = Lwt.fail Cohttp_lwt_xhr_callv_not_implemented

  (* ??? *)
end

module Make_client_async (P : Params) = Make_api (struct
  module Response = Cohttp.Response
  module Request = Cohttp.Request
  module Bb = Body_builder (P)

  let call ?headers ?body meth uri =
    let xml = XmlHttpRequest.create () in
    xml##.withCredentials := Js.bool P.with_credentials;
    if xhr_response_supported then xml##.responseType := Js.string "arraybuffer";
    let (res : (Response.t Lwt.t * CLB.t) Lwt.t), wake = Lwt.task () in
    let () =
      xml
      ## (_open
            (Js.string (C.Code.string_of_method meth))
            (Js.string (Uri.to_string uri))
            Js._true)
      (* asynchronous call *)
    in
    (* set request headers *)
    let () =
      match headers with
      | None -> ()
      | Some headers ->
          C.Header.iter
            (fun k v ->
              (* some headers lead to errors in the javascript console, should
                 we filter then out here? *)
              xml ## (setRequestHeader (Js.string k) (Js.string v)))
            headers
    in

    xml##.onreadystatechange :=
      Js.wrap_callback (fun _ ->
          match xml##.readyState with
          | XmlHttpRequest.DONE -> (
              try
                let body = Bb.construct_body xml in
                (* Note; a type checker subversion seems to be possible here (4.01.0).
                 * Remove the type constraint on Lwt.task above and return any old
                 * guff here.  It'll compile and crash in the browser! *)
                (* (re-)construct the response *)
                let resp_headers = Js.to_string xml##getAllResponseHeaders in
                let channel = String_io.open_in resp_headers in
                let response =
                  Lwt.(
                    Header_io.parse channel >|= fun resp_headers ->
                    Cohttp.Response.make ~version:`HTTP_1_1
                      ~status:(C.Code.status_of_code xml##.status)
                      ~flush:false (* ??? *)
                      ~encoding:(CLB.transfer_encoding body)
                      ~headers:resp_headers ())
                in
                Lwt.wakeup wake (response, body)
              with
              | e
              (* If we exhaust the stack, it is possible that
                 Lwt.wakeup just aboves marks the promise as
                 completed, but raises Stack_overflow while
                 running the promise callbacks. In this case
                 waking calling wakeup_exn on the already
                 completed promise would raise an Invalid_arg
                 exception, so although the promise is in a
                 really bad state we may as well let the actual
                 Stack_overflow exception go through. *)
              when Lwt.state res = Lwt.Sleep
              ->
                Lwt.wakeup_exn wake e)
          | _ -> ());

    (* perform call *)
    (match body with
    | None -> Lwt.return xml ## (send Js.null)
    | Some body ->
        CLB.to_string body >>= fun body ->
        let bs = binary_string body in
        (*Js.Opt.case (File.CoerceTo.blob (Obj.magic blob))
          (fun () -> Lwt.fail_with "could not coerce to blob")
          (fun blob -> Lwt.return (xml##(send_blob blob)))*)
        (*Lwt.return (xml##send (Js.Opt.return bs)) *)
        Lwt.return (xml##send (Js.Opt.return (Obj.magic bs))))
    >>= fun () ->
    Lwt.on_cancel res (fun () -> xml##abort);
    (* unwrap the response *)
    Lwt.(
      res >>= fun (r, b) ->
      r >>= fun r -> Lwt.return (r, b))
end)

module Make_client_sync (P : Params) = Make_api (struct
  module Response = Cohttp.Response
  module Request = Cohttp.Request
  module Bb = Body_builder (P)

  let call ?headers ?body meth uri =
    let xml = XmlHttpRequest.create () in
    xml##.withCredentials := Js.bool P.with_credentials;
    if xhr_response_supported then xml##.responseType := Js.string "arraybuffer";
    let () =
      xml
      ## (_open
            (Js.string (C.Code.string_of_method meth))
            (Js.string (Uri.to_string uri))
            Js._false)
      (* synchronous call *)
    in
    (* set request headers *)
    let () =
      match headers with
      | None -> ()
      | Some headers ->
          C.Header.iter
            (fun k v ->
              (* some headers lead to errors in the javascript console, should
                 we filter then out here? *)
              xml ## (setRequestHeader (Js.string k) (Js.string v)))
            headers
    in
    (* perform call *)
    (match body with
    | None -> Lwt.return xml ## (send Js.null)
    | Some body ->
        CLB.to_string body >|= fun body ->
        let bs = binary_string body in
        xml ## (send (Js.Opt.return (Obj.magic bs))))
    >>= fun _body ->
    let body = Bb.construct_body xml in
    (* (re-)construct the response *)
    let resp_headers = Js.to_string xml##getAllResponseHeaders in
    Header_io.parse (String_io.open_in resp_headers) >>= fun resp_headers ->
    let response =
      Response.make ~version:`HTTP_1_1
        ~status:(Cohttp.Code.status_of_code xml##.status)
        ~flush:false
        ~encoding:(CLB.transfer_encoding body)
        ~headers:resp_headers ()
    in

    Lwt.return (response, body)
end)

module Client = Make_client_async (struct
  let chunked_response = true
  let chunk_size = 128 * 1024
  let convert_body_string = Js.to_bytestring
  let with_credentials = false
end)

module Client_sync = Make_client_sync (struct
  let chunked_response = false
  let chunk_size = 0
  let convert_body_string = Js.to_bytestring
  let with_credentials = false
end)

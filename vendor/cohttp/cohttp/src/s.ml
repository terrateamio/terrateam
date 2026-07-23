(*{{{ Copyright (C) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2014 Rudi Grinberg
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

(** Module type signatures for Cohttp components *)

(** The [IO] module defines the blocking interface for reading and writing to
    Cohttp streams *)
module type IO = sig
  type +'a t
  (** ['a t] represents a blocking monad state *)

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  (** [a >>= b] will pass the result of [a] to the [b] function. This is a
      monadic [bind]. *)

  val return : 'a -> 'a t
  (** [return a] will construct a constant IO value. *)

  type ic
  (** [ic] represents an input channel *)

  type oc
  (** [oc] represents an output channel *)

  type conn
  (** [conn] represents the underlying network flow *)

  val read_line : ic -> string option t
  (** [read_line ic] will read a single line terminated by CR or CRLF from the
      input channel [ic]. It returns {!None} if EOF or other error condition is
      reached. *)

  val read : ic -> int -> string t
  (** [read ic len] will block until a maximum of [len] characters are read from
      the input channel [ic]. It returns an empty string if EOF or some other
      error condition occurs on the input channel, and can also return fewer
      than [len] characters if input buffering is not sufficient to satisfy the
      request. *)

  val write : oc -> string -> unit t
  (** [write oc s] will block until the complete [s] string is written to the
      output channel [oc]. *)

  val flush : oc -> unit t
  (** [flush oc] will return when all previously buffered content from calling
      {!write} have been written to the output channel [oc]. *)
end

module type Http_io = sig
  type t
  type reader
  type writer

  module IO : IO

  val read : IO.ic -> [ `Eof | `Invalid of string | `Ok of t ] IO.t
  val has_body : t -> [ `No | `Unknown | `Yes ]
  val make_body_writer : ?flush:bool -> t -> IO.oc -> writer
  val make_body_reader : t -> IO.ic -> reader
  val read_body_chunk : reader -> Transfer.chunk IO.t
  val write_header : t -> IO.oc -> unit IO.t
  val write_body : writer -> string -> unit IO.t
  val write : ?flush:bool -> (writer -> unit IO.t) -> t -> IO.oc -> unit IO.t
end

module type Request = sig
  type t = {
    headers : Header.t;  (** HTTP request headers *)
    meth : Code.meth;  (** HTTP request method *)
    scheme : string option;  (** URI scheme (http or https) *)
    resource : string;  (** Request path and query *)
    version : Code.version;  (** HTTP version, usually 1.1 *)
    encoding : Transfer.encoding;  (** transfer encoding of this HTTP request *)
  }
  [@@deriving sexp]

  val headers : t -> Header.t
  val meth : t -> Code.meth
  val scheme : t -> string option
  val resource : t -> string
  val version : t -> Code.version
  val encoding : t -> Transfer.encoding
  val compare : t -> t -> int

  val make :
    ?meth:Code.meth ->
    ?version:Code.version ->
    ?encoding:Transfer.encoding ->
    ?headers:Header.t ->
    Uri.t ->
    t

  val is_keep_alive : t -> bool
  (** Return true whether the connection should be reused *)

  val uri : t -> Uri.t

  val make_for_client :
    ?headers:Header.t ->
    ?chunked:bool ->
    ?body_length:int64 ->
    Code.meth ->
    Uri.t ->
    t
end

module type Response = sig
  type t = {
    encoding : Transfer.encoding;
        (** Transfer encoding of this HTTP response *)
    headers : Header.t;  (** response HTTP headers *)
    version : Code.version;  (** (** HTTP version, usually 1.1 *) *)
    status : Code.status_code;  (** HTTP status code of the response *)
    flush : bool;
  }
  [@@deriving sexp]

  val encoding : t -> Transfer.encoding
  val headers : t -> Header.t
  val version : t -> Code.version
  val status : t -> Code.status_code
  val flush : t -> bool
  val compare : t -> t -> int

  val make :
    ?version:Code.version ->
    ?status:Code.status_code ->
    ?flush:bool ->
    ?encoding:Transfer.encoding ->
    ?headers:Header.t ->
    unit ->
    t
  (** The response creates by [make ~encoding ~headers ()] has an encoding value
      determined from the content of [headers] or if no proper header is
      present, using the value of [encoding]. Checked headers are
      "content-length", "content-range" and "transfer-encoding". The default
      value of [encoding] is chunked. *)
end

module type Body = sig
  type t

  val to_string : t -> string
  val to_string_list : t -> string list
  val to_form : t -> (string * string list) list
  val empty : t
  val is_empty : t -> bool
  val of_string : string -> t
  val of_string_list : string list -> t
  val of_form : ?scheme:string -> (string * string list) list -> t
  val map : (string -> string) -> t -> t
  val transfer_encoding : t -> Transfer.encoding
end

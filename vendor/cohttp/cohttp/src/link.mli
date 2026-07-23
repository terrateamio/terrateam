(*{{{ Copyright (c) 2015 David Sheets <sheets@alum.mit.edu>
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

(** RFC 5988 ("Web Linking") and RFC 5987 ("Character Set and Language Encoding
    for Hypertext Transfer Protocol (HTTP) Header Field Parameters") *)

module Rel : sig
  type t [@@deriving sexp]

  val extension : Uri.t -> t
  val alternate : t
  val appendix : t
  val bookmark : t
  val chapter : t
  val contents : t
  val copyright : t
  val current : t
  val described_by : t
  val edit : t
  val edit_media : t
  val enclosure : t
  val first : t
  val glossary : t
  val help : t
  val hub : t
  val index : t
  val last : t
  val latest_version : t
  val license : t
  val next : t
  val next_archive : t
  val payment : t
  val predecessor_version : t
  val prev : t
  val prev_archive : t
  val related : t
  val replies : t
  val section : t
  val self : t
  val service : t
  val start : t
  val stylesheet : t
  val subsection : t
  val successor_version : t
  val up : t
  val version_history : t
  val via : t
  val working_copy : t
  val working_copy_of : t
end

module Language : sig
  type t = private string [@@deriving sexp]

  val to_string : t -> string
  val of_string : string -> t
end

module Charset : sig
  type t = private string [@@deriving sexp]

  val to_string : t -> string
  val of_string : string -> t
end

module Ext : sig
  type 'a t [@@deriving sexp]

  val charset : 'a t -> Charset.t
  val language : 'a t -> Language.t
  val value : 'a t -> 'a
  val make : ?charset:Charset.t -> ?language:Language.t -> 'a -> 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end

module Arc : sig
  type t = {
    reverse : bool;
    relation : Rel.t list;
    hreflang : string option;
    media : string option;
    title : string option;
    title_ext : string Ext.t option;
    media_type : (string * string) option;
    extensions : (string * string) list;
    extension_exts : (string * string Ext.t) list;
  }

  val empty : t
end

type t = { context : Uri.t; arc : Arc.t; target : Uri.t } [@@deriving sexp]

val empty : t
val of_string : string -> t list
val to_string : t -> string

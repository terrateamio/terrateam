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

(** HTTP Authentication and Authorization header parsing and generation *)

type challenge = [ `Basic of string  (** Basic authentication within a realm *) ]
[@@deriving sexp]
(** HTTP authentication challenge types *)

type credential =
  [ `Basic of string * string
    (** Basic authorization with a username and password *)
  | `Other of string
    (** An unknown credential type that will be passed straight through to the
        application layer *) ]
[@@deriving sexp]
(** HTTP authorization credential types *)

val string_of_credential : credential -> string
(** [string_of_credential] converts the {!credential} to a string compatible
    with the HTTP/1.1 wire format for authorization credentials ("responses") *)

val credential_of_string : string -> credential
(** [credential_of_string cred_s] converts an HTTP response to an authentication
    challenge into a {!credential}. If the credential is not recognized,
    [`Other cred_s] is returned. *)

val string_of_challenge : challenge -> string
(** [string_of_challenge challenge] converts the {!challenge} to a string
    compatible with the HTTP/1.1 wire format for authentication challenges.

    For example, a [`Basic] challenge with realm ["foo"] will be marshalled to
    ["Basic realm=foo"], which can then be combined with a [www-authenticate]
    HTTP header and sent back to the client. There is a helper function
    {!Header.add_authorization_req} that does just this. *)

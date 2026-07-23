(*
 * Copyright (c) 2012-2015 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt.Infix

module Make
    (P : Mirage_clock.PCLOCK)
    (R : Resolver_mirage.S)
    (S : Conduit_mirage.S) =
struct
  module Channel = Mirage_channel.Make (S.Flow)
  module HTTP_IO = Io.Make (Channel)
  module Endpoint = Conduit_mirage.Endpoint (P)

  module Net_IO = struct
    module IO = HTTP_IO

    type ctx = {
      resolver : R.t;
      conduit : S.t option;
      authenticator : X509.Authenticator.t option;
    }

    let sexp_of_ctx { resolver; _ } = R.sexp_of_t resolver

    let default_ctx =
      { resolver = R.localhost; conduit = None; authenticator = None }

    let connect_uri ~ctx:{ resolver; conduit; authenticator } uri =
      R.resolve_uri ~uri resolver >>= fun endp ->
      Endpoint.client ?tls_authenticator:authenticator endp >>= fun client ->
      match conduit with
      | None -> failwith "conduit not initialised"
      | Some c ->
          S.connect c client >>= fun flow ->
          let ch = Channel.create flow in
          Lwt.return (flow, ch, ch)

    let close_in _ = ()
    let close_out _ = ()

    let close ic _oc =
      Lwt.ignore_result
      @@ Lwt.catch
           (fun () -> Channel.close ic)
           (fun e ->
             Logs.warn (fun f ->
                 f "Closing channel failed: %s" (Printexc.to_string e));
             Lwt.return @@ Ok ())
  end

  let ctx ?authenticator resolver conduit =
    { Net_IO.resolver; conduit = Some conduit; authenticator }

  let with_authenticator a ctx = { ctx with Net_IO.authenticator = Some a }

  (* Build all the core modules from the [Cohttp_lwt] functors *)
  include Cohttp_lwt.Make_client (HTTP_IO) (Net_IO)
end

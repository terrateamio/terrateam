(*{{{ Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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

open Transfer

module Make (IO : S.IO) = struct
  open IO

  type reader = unit -> Transfer.chunk IO.t
  type writer = string -> unit IO.t

  module Chunked = struct
    let remaining_length chunk remaining =
      let read_len = Int64.of_int (String.length chunk) in
      Int64.sub remaining read_len

    let read_chunk ic size =
      let max_read_len = Int64.of_int 0x8000 in
      let len = min size max_read_len in
      read ic (Int64.to_int len)

    let parse_chunksize chunk_size_hex =
      let hex =
        (* From https://tools.ietf.org/html/rfc7230#section-4.1.1
           > The chunked encoding allows each chunk to include zero or
           > more chunk extensions, immediately following the chunk-size
        *)
        try String.sub chunk_size_hex 0 (String.index chunk_size_hex ';')
        with _ -> chunk_size_hex
      in
      try Some (Int64.of_string ("0x" ^ hex)) with _ -> None

    let rec junk_until_empty_line ic =
      read_line ic >>= function
      | None | Some "" -> return Done
      | Some _trailer -> junk_until_empty_line ic

    let read ~remaining ic () =
      (* read between 0 and 32Kbytes of a chunk *)
      let read_chunk_fragment () =
        read_chunk ic !remaining >>= fun chunk ->
        remaining := remaining_length chunk !remaining;
        (if !remaining = 0L (* End_of_chunk *) then read_line ic
         (* Junk the CRLF at end of chunk *)
        else return None)
        >>= fun _ -> return chunk
      in
      if !remaining = 0L then
        (* Beginning of a chunk: read chunk size, read up to 32K bytes *)
        read_line ic >>= function
        | None -> return Done
        | Some chunk_size_hex -> (
            match parse_chunksize chunk_size_hex with
            | None -> return Done
            | Some 0L ->
                (* TODO: Trailer header support *)
                junk_until_empty_line ic
            | Some count -> (
                remaining := count;
                read_chunk_fragment () >>= function
                | "" -> return Done (* 0 bytes read means EOF *)
                | buf -> return (Chunk buf)))
      else
        (* Middle of a chunk, read up to 32K bytes *)
        read_chunk_fragment () >>= function
        | "" -> return Done (* 0 bytes read means EOF *)
        | buf -> return (Chunk buf)

    let write oc buf =
      let len = String.length buf in
      (* do NOT send empty chunks, as it signals the end of the
         chunked body *)
      if len <> 0 then
        write oc (Printf.sprintf "%x\r\n" len) >>= fun () ->
        write oc buf >>= fun () -> write oc "\r\n"
      else return ()
  end

  module Fixed = struct
    let read ~remaining ic () =
      (* TODO functorise string to a bigbuffer *)
      match !remaining with
      | 0L -> return Done
      | len -> (
          let max_read_len = Int64.of_int 0x8000 in
          let read_len = Int64.to_int (min len max_read_len) in
          read ic read_len >>= function
          | "" -> return Done
          | buf ->
              remaining :=
                Int64.sub !remaining (Int64.of_int (String.length buf));
              return
                (match !remaining with 0L -> Final_chunk buf | _ -> Chunk buf))

    (* TODO enforce that the correct length is written? *)
    let write = write
  end

  module Unknown = struct
    (* If we have no idea, then read until EOF (connection shutdown by
       the remote party). *)
    let read ic () =
      read ic 4096 >>= fun buf ->
      if buf = "" then return Done else return (Chunk buf)

    let write = write
  end

  let write_and_flush fn oc buf = fn oc buf >>= fun () -> IO.flush oc

  let make_reader = function
    | Chunked -> Chunked.read ~remaining:(ref 0L)
    | Fixed len -> Fixed.read ~remaining:(ref len)
    | Unknown -> Fixed.read ~remaining:(ref 0L)

  let write_ignore_blank writer io s =
    if String.length s = 0 then return () else writer io s

  let make_writer ?(flush = false) mode =
    match flush with
    | false -> (
        match mode with
        | Chunked -> Chunked.write
        | Fixed _ -> Fixed.write
        | Unknown -> Unknown.write)
    | true ->
        (match mode with
        | Chunked -> write_and_flush Chunked.write
        | Fixed _ -> write_and_flush Fixed.write
        | Unknown -> write_and_flush Unknown.write)
        |> write_ignore_blank

  let read reader = reader ()
  let write writer buf = writer buf
end

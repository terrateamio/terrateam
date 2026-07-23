(*{{{ Copyright (c) 2014-2015 David Sheets <sheets@alum.mit.edu>
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

(* This module contains I/O agnostic functions used by
   Cohttp_server_lwt and Cohttp_server_async. *)

open Printf

let ( / ) = Filename.concat

let compare_kind = function
  | Some `Directory, Some `Directory -> 0
  | Some `Directory, _ -> -1
  | _, Some `Directory -> 1
  | Some `File, Some `File -> 0
  | Some `File, _ -> 1
  | _, Some `File -> -1
  | _, _ -> 0

let sort lst =
  List.sort
    (fun (ka, _sa, a) (kb, _sb, b) ->
      let c = compare_kind (ka, kb) in
      if c <> 0 then c
      else String.compare (String.lowercase_ascii a) (String.lowercase_ascii b))
    lst

let li ?title l =
  let title =
    match title with None -> "" | Some s -> sprintf "title=\"%s\" " s
  in
  sprintf "<li><a %shref=\"%s\">%s</a></li>" title (Uri.to_string l)

let kind_of_unix_kind =
  Unix.(
    function
    | S_DIR -> `Directory
    | S_REG -> `File
    | S_SOCK -> `Socket
    | S_BLK -> `Block
    | S_FIFO -> `Fifo
    | S_CHR -> `Char
    | S_LNK -> `Link)

let human_size_of_size size =
  let size = Int64.to_float size in
  let kibi = size /. 1024. in
  if kibi < 1. then sprintf "%.0fB" size
  else
    let mibi = kibi /. 1024. in
    if mibi < 1. then sprintf "%.1fKiB" kibi
    else
      let gibi = mibi /. 1024. in
      if gibi < 1. then sprintf "%.1fMiB" mibi else sprintf "%.1fGiB" gibi

let html_of_listing uri path listing info =
  let html =
    List.map
      (fun (kind, size, f) ->
        let encoded_f = Uri.pct_encode f in
        match kind with
        | Some `Directory ->
            let link = Uri.with_path uri (path / encoded_f / "") in
            li link (sprintf "<i>%s/</i>" f)
        | Some `File ->
            let link = Uri.with_path uri (path / encoded_f) in
            li ~title:(human_size_of_size size) link f
        | Some (`Socket | `Block | `Fifo | `Char | `Link) ->
            sprintf "<li><s>%s</s></li>" f
        | None -> sprintf "<li>Error with file: %s</li>" f)
      (sort listing)
  in
  let contents = String.concat "\n" html in
  sprintf
    "<html><body><h2>Directory Listing for <em>%s</em></h2><ul>%s</ul><hr \
     />%s</body></html>"
    (Uri.pct_decode path) contents info

let html_of_forbidden_unnormal path info =
  sprintf
    "<html><body><h2>Forbidden</h2><p><b>%s</b>is not a normal file or \
     directory</p><hr/>%s</body></html>"
    path info

let html_of_not_found path info =
  sprintf
    "<html><body><h2>Not Found</h2><p><b>%s</b>was not found on this \
     server</p><hr />%s</body></html>"
    path info

let html_of_method_not_allowed meth allowed path info =
  sprintf
    "<html><body><h2>Method Not Allowed</h2><p><b>%s</b>is not an allowed \
     method on <b>%s</b></p><p>Allowed methods on <b>%s</b> are \
     <b>%s</b></p><hr />%s</body></html>"
    meth path path allowed info

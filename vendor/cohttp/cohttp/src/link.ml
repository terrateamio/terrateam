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

open Sexplib0.Sexp_conv

(* From <https://tools.ietf.org/html/rfc5988> *)
module Rel = struct
  type t =
    | Extension of Uri_sexp.t
    | Alternate
    | Appendix
    | Bookmark
    | Chapter
    | Contents
    | Copyright
    | Current
    | Described_by
    | Edit
    | Edit_media
    | Enclosure
    | First
    | Glossary
    | Help
    | Hub
    | Index
    | Last
    | Latest_version
    | License
    | Next
    | Next_archive
    | Payment
    | Predecessor_version
    | Prev
    | Prev_archive
    | Related
    | Replies
    | Section
    | Self
    | Service
    | Start
    | Stylesheet
    | Subsection
    | Successor_version
    | Up
    | Version_history
    | Via
    | Working_copy
    | Working_copy_of
  [@@deriving sexp]

  let extension uri = Extension uri
  let alternate = Alternate
  let appendix = Appendix
  let bookmark = Bookmark
  let chapter = Chapter
  let contents = Contents
  let copyright = Copyright
  let current = Current
  let described_by = Described_by
  let edit = Edit
  let edit_media = Edit_media
  let enclosure = Enclosure
  let first = First
  let glossary = Glossary
  let help = Help
  let hub = Hub
  let index = Index
  let last = Last
  let latest_version = Latest_version
  let license = License
  let next = Next
  let next_archive = Next_archive
  let payment = Payment
  let predecessor_version = Predecessor_version
  let prev = Prev
  let prev_archive = Prev_archive
  let related = Related
  let replies = Replies
  let section = Section
  let self = Self
  let service = Service
  let start = Start
  let stylesheet = Stylesheet
  let subsection = Subsection
  let successor_version = Successor_version
  let up = Up
  let version_history = Version_history
  let via = Via
  let working_copy = Working_copy
  let working_copy_of = Working_copy_of
end

module Language = struct
  type t = string [@@deriving sexp]

  let to_string x = x
  let of_string x = x
end

module Charset = struct
  type t = string [@@deriving sexp]

  let to_string x = x
  let of_string x = x
end

module Ext = struct
  type 'a t = { charset : Charset.t; language : Language.t; value : 'a }
  [@@deriving sexp]

  let charset t = t.charset
  let language t = t.language
  let value t = t.value
  let make ?(charset = "") ?(language = "") value = { charset; language; value }
  let map f x = { x with value = f x.value }
end

module Arc = struct
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
  [@@deriving sexp]

  let empty =
    {
      reverse = false;
      relation = [];
      hreflang = None;
      media = None;
      title = None;
      title_ext = None;
      media_type = None;
      extensions = [];
      extension_exts = [];
    }
end

type t = { context : Uri_sexp.t; arc : Arc.t; target : Uri_sexp.t }
[@@deriving sexp]

(* TODO: this could be replaced with empty t/arc fupdate *)
type param =
  | Rel of Rel.t list
  | Anchor of Uri.t
  | Rev of Rel.t list
  | Hreflang of Language.t
  | Media of string
  | Title of string
  | Star of param Ext.t
  | Type of (string * string)
  | Link_extension of string * string

let until s start cl =
  let nextl =
    List.map
      (fun c ->
        let pattern = String.make 1 c in
        Stringext.find_from ~start s ~pattern)
      cl
  in
  let min =
    List.fold_left
      (fun min_opt i_opt ->
        match (min_opt, i_opt) with
        | None, None -> None
        | Some i, None | None, Some i -> Some i
        | Some i, Some j -> Some (min i j))
      None nextl
  in
  match min with
  | None -> (Stringext.string_after s start, String.length s)
  | Some i -> (String.sub s start (i - start), i)

let string_of_rel =
  Rel.(
    function
    | Alternate -> "alternate"
    | Appendix -> "appendix"
    | Bookmark -> "bookmark"
    | Chapter -> "chapter"
    | Contents -> "contents"
    | Copyright -> "copyright"
    | Current -> "current"
    | Described_by -> "describedby"
    | Edit -> "edit"
    | Edit_media -> "edit-media"
    | Enclosure -> "enclosure"
    | First -> "first"
    | Glossary -> "glossary"
    | Help -> "help"
    | Hub -> "hub"
    | Index -> "index"
    | Last -> "last"
    | Latest_version -> "latest-version"
    | License -> "license"
    | Next -> "next"
    | Next_archive -> "next-archive"
    | Payment -> "payment"
    | Predecessor_version -> "predecessor-version"
    | Prev -> "prev"
    | Prev_archive -> "prev-archive"
    | Related -> "related"
    | Replies -> "replies"
    | Section -> "section"
    | Self -> "self"
    | Service -> "service"
    | Start -> "start"
    | Stylesheet -> "stylesheet"
    | Subsection -> "subsection"
    | Successor_version -> "successor-version"
    | Up -> "up"
    | Version_history -> "version-history"
    | Via -> "via"
    | Working_copy -> "working-copy"
    | Working_copy_of -> "working-copy-of"
    | Extension uri -> Uri.to_string uri)

let rel_of_string s =
  Rel.(
    try
      ignore (String.index s ':');
      Extension (Uri.of_string s)
    with Not_found -> (
      match s with
      | "alternate" -> Alternate
      | "appendix" -> Appendix
      | "bookmark" -> Bookmark
      | "chapter" -> Chapter
      | "contents" -> Contents
      | "copyright" -> Copyright
      | "current" -> Current
      | "describedby" -> Described_by
      | "edit" -> Edit
      | "edit-media" -> Edit_media
      | "enclosure" -> Enclosure
      | "first" -> First
      | "glossary" -> Glossary
      | "help" -> Help
      | "hub" -> Hub
      | "index" -> Index
      | "last" -> Last
      | "latest-version" -> Latest_version
      | "license" -> License
      | "next" -> Next
      | "next-archive" -> Next_archive
      | "payment" -> Payment
      | "predecessor-version" -> Predecessor_version
      | "prev" | "previous" -> Prev
      | "prev-archive" -> Prev_archive
      | "related" -> Related
      | "replies" -> Replies
      | "section" -> Section
      | "self" -> Self
      | "service" -> Service
      | "start" -> Start
      | "stylesheet" -> Stylesheet
      | "subsection" -> Subsection
      | "successor-version" -> Successor_version
      | "up" -> Up
      | "version-history" -> Version_history
      | "via" -> Via
      | "working-copy" -> Working_copy
      | "working-copy-of" -> Working_copy_of
      | _ -> Extension (Uri.of_string s)))

let quoted_string_of_string s q =
  let rec first_quote q =
    match s.[q] with
    | ' ' -> first_quote (q + 1)
    | '"' -> (
        let q = q + 1 in
        match Stringext.find_from ~start:q s ~pattern:"\"" with
        | None -> (Stringext.string_after s q, String.length s)
        | Some q' -> (String.sub s q (q' - q), q' + 1))
    | _ -> until s q [ ';'; ',' ]
  in
  first_quote q

let rels_of_string_ s q =
  let qs, i = quoted_string_of_string s q in
  let rels = Stringext.split qs ~on:' ' in
  (List.map rel_of_string (List.filter (fun s -> String.length s > 0) rels), i)

let rels_of_string s i =
  match
    (Stringext.find_from ~start:i s ~pattern:"\"", until s i [ ';'; ',' ])
  with
  | Some q, (_, d) when q < d -> rels_of_string_ s q
  | _, (s, d) -> ([ rel_of_string s ], d)

let anchor_of_string s i =
  let qs, i = quoted_string_of_string s i in
  (Uri.of_string qs, i)

let star_of_string s i =
  match Stringext.find_from ~start:i s ~pattern:"'" with
  | None ->
      let s, i = quoted_string_of_string s i in
      ("", "", s, i)
  | Some a -> (
      let charset = String.sub s i (a - i) in
      let i = a + 1 in
      match Stringext.find_from ~start:i s ~pattern:"'" with
      | None ->
          let s, i = quoted_string_of_string s i in
          (charset, "", s, i)
      | Some a ->
          let language = String.sub s i (a - i) in
          let i = a + 1 in
          let s, i = quoted_string_of_string s i in
          (charset, language, s, i))

let media_type_of_string s i =
  let mt, i = quoted_string_of_string s i in
  match Stringext.split ~max:2 mt ~on:'/' with
  | [] -> (("", ""), i)
  | [ t ] -> ((t, ""), i)
  | t :: st :: _ -> ((t, st), i)

let rec params_of_string s i ps =
  let _, d = until s i [ ';'; ',' ] in
  if d = String.length s then (ps, None)
  else if s.[d] = ',' then (ps, Some d)
  else
    let i = d + 1 in
    let param, i = until s i [ '=' ] in
    let i = i + 1 in
    match String.trim param with
    | "rel" ->
        let rels, i = rels_of_string s i in
        params_of_string s i (Rel rels :: ps)
    | "anchor" ->
        let uri, i = anchor_of_string s i in
        params_of_string s i (Anchor uri :: ps)
    | "rev" ->
        let rels, i = rels_of_string s i in
        params_of_string s i (Rev rels :: ps)
    | "hreflang" ->
        let hreflang, i = until s i [ ','; ';' ] in
        params_of_string s i (Hreflang hreflang :: ps)
    | "media" ->
        let media, i = quoted_string_of_string s i in
        params_of_string s i (Media media :: ps)
    | "title" ->
        let title, i = quoted_string_of_string s i in
        params_of_string s i (Title title :: ps)
    | "title*" ->
        let charset, language, v, i = star_of_string s i in
        params_of_string s i
          (Star { Ext.charset; language; value = Title v } :: ps)
    | "type" ->
        let media_type, i = media_type_of_string s i in
        params_of_string s i (Type media_type :: ps)
    | other when String.length other = 0 ->
        let s, i = quoted_string_of_string s i in
        params_of_string s i (Link_extension ("", s) :: ps)
    | other ->
        let last = String.length other - 1 in
        if other.[last] = '*' then
          let main = String.sub other 0 last in
          let charset, language, v, i = star_of_string s i in
          params_of_string s i
            (Star { Ext.charset; language; value = Link_extension (main, v) }
            :: ps)
        else
          let v, i = quoted_string_of_string s i in
          params_of_string s i (Link_extension (other, v) :: ps)

let rec find_or_default f d = function
  | [] -> d
  | h :: t -> ( match f h with None -> find_or_default f d t | Some v -> v)

let arc_of_relation_params ?(reverse = false) relation params =
  let extensions, extension_exts =
    List.fold_left
      (fun (x, xx) -> function
        | Link_extension (k, v) -> ((k, v) :: x, xx)
        | Star { Ext.charset; language; value = Link_extension (k, value) } ->
            (x, (k, { Ext.charset; language; value }) :: xx)
        | _ -> (x, xx))
      ([], []) params
  in
  {
    Arc.reverse;
    relation;
    hreflang =
      find_or_default
        (function Hreflang l -> Some (Some l) | _ -> None)
        None params;
    media =
      find_or_default
        (function Media m -> Some (Some m) | _ -> None)
        None params;
    title =
      find_or_default
        (function Title t -> Some (Some t) | _ -> None)
        None params;
    title_ext =
      find_or_default
        (function
          | Star { Ext.charset; language; value = Title t } ->
              Some (Some { Ext.charset; language; value = t })
          | _ -> None)
        None params;
    media_type =
      find_or_default
        (function Type mt -> Some (Some mt) | _ -> None)
        None params;
    extensions;
    extension_exts;
  }

let empty =
  { context = Uri.of_string ""; arc = Arc.empty; target = Uri.of_string "" }

let rec unfold s list start =
  match Stringext.find_from ~start s ~pattern:"<" with
  | None -> list
  | Some i -> (
      let uri_ref, i = until s (i + 1) [ '>' ] in
      let i = i + 1 in
      let target = Uri.of_string uri_ref in
      let params, c_opt = params_of_string s i [] in
      let params = List.rev params in
      let context =
        find_or_default
          (function Anchor uri -> Some uri | _ -> None)
          (Uri.of_string "") params
      in
      let link =
        match
          find_or_default
            (function Rel rels -> Some rels | _ -> None)
            [] params
        with
        | _ :: _ as relation ->
            let arc = arc_of_relation_params relation params in
            { context; arc; target }
        | [] -> (
            match
              find_or_default
                (function Rev rels -> Some rels | _ -> None)
                [] params
            with
            | [] ->
                let arc = arc_of_relation_params [] params in
                { context; arc; target }
            | rev ->
                let arc = arc_of_relation_params ~reverse:true rev params in
                { context = target; arc; target = context })
      in
      let list = link :: list in
      match c_opt with None -> list | Some c -> unfold s list c)

let of_string s = List.rev (unfold s [] 0)

open Printf

let arc_to_string context arc =
  Arc.(
    let attrs =
      match arc.relation with
      | [] -> []
      | rels ->
          [
            sprintf "%s=\"%s\""
              (if arc.reverse then "rev" else "rel")
              (String.concat " " (List.map string_of_rel rels));
          ]
    in
    let attrs =
      match arc.hreflang with
      | None -> attrs
      | Some s -> ("hreflang=" ^ s) :: attrs
    in
    let attrs =
      match arc.media with
      | None -> attrs
      | Some s -> sprintf "media=\"%s\"" s :: attrs
    in
    let attrs =
      match arc.title with
      | None -> attrs
      | Some s -> sprintf "title=%S" s :: attrs
      (* TODO: this isn't quite right...*)
    in
    let attrs =
      match arc.title_ext with
      | None -> attrs
      | Some { Ext.charset; language; value } ->
          sprintf "title*=%s'%s'%s" charset language value :: attrs
    in
    let attrs =
      match arc.media_type with
      | None -> attrs
      | Some (typ, sub) -> sprintf "type=%s/%s" typ sub :: attrs
    in
    let attrs =
      List.map (fun (k, v) -> sprintf "%s=%S" k v) arc.extensions @ attrs
    in
    let attrs =
      List.map
        (fun (k, { Ext.charset; language; value }) ->
          sprintf "%s=%s'%s'%s" k charset language value)
        arc.extension_exts
      @ attrs
    in
    let attrs =
      if context = Uri.of_string "" then attrs
      else sprintf "anchor=\"%s\"" (Uri.to_string context) :: attrs
    in
    String.concat "; " attrs)

let to_string { context; arc; target } =
  sprintf "<%s>; %s" (Uri.to_string target) (arc_to_string context arc)

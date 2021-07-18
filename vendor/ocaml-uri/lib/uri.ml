(*
 * Copyright (c) 2012-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2012-2014 David Sheets <sheets@alum.mit.edu>
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
 *)

[@@@ocaml.warning "-32"]

type component = [
  | `Scheme
  | `Authority
  | `Userinfo (* subcomponent of authority in some schemes *)
  | `Host (* subcomponent of authority in some schemes *)
  | `Path
  | `Query
  | `Query_key
  | `Query_value
  | `Fragment
  | `Generic
  | `Custom of (component * string * string) (* (component * safe chars * unsafe chars) *)
]

type pct_encoder = {
    scheme: component;
    userinfo: component;
    host: component;
    path: component;
    query_key: component;
    query_value: component;
    fragment: component;
  }

let rec iter_concat fn sep buf = function
  | last::[] -> fn buf last
  | el::rest ->
    fn buf el;
    Buffer.add_string buf sep;
    iter_concat fn sep buf rest
  | [] -> ()

let rev_interject e lst =
  let rec aux acc = function
    | []  -> acc
    | x::xs -> aux (x::e::acc) xs
  in match lst with
  | []  -> []
  | h::t -> aux [h] t

let compare_opt c t t' = match t, t' with
  | None,   None   -> 0
  | Some _, None   -> 1
  | None,   Some _ -> -1
  | Some a, Some b -> c a b

let rec compare_list f t t' = match t, t' with
  | [],    []    ->  0
  | _::_,  []    ->  1
  | [],    _::_  -> -1
  | x::xs, y::ys ->
    match f x y with 0 -> compare_list f xs ys | c -> c

(** Safe characters that are always allowed in a URI
  * Unfortunately, this varies depending on which bit of the URI
  * is being parsed, so there are multiple variants (and this
  * set is probably not exhaustive. TODO: check.
*)
type safe_chars = bool array

module type Scheme = sig
  val safe_chars_for_component : component -> safe_chars
  val normalize_host : string option -> string option
  val canonicalize_port : int option -> int option
  val canonicalize_path : string list -> string list
end

module Generic : Scheme = struct
  let sub_delims a =
    let subd = "!$&'()*+,;=" in
    for i = 0 to String.length subd - 1 do
      let c = Char.code subd.[i] in
      a.(c) <- true
    done;
    a

  let safe_chars : safe_chars =
    let a = Array.make 256 false in
    let always_safe =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-~" in
    for i = 0 to String.length always_safe - 1 do
      let c = Char.code always_safe.[i] in
      a.(c) <- true
    done;
    a

  let pchar : safe_chars =
    let a = sub_delims (Array.copy safe_chars) in
    a.(Char.code ':') <- true;
    a.(Char.code '@') <- true;
    a

  let safe_chars_for_scheme : safe_chars =
    let a = Array.copy safe_chars in
    a.(Char.code '+') <- true;
    a

  (** Safe characters for the path component of a URI *)
  let safe_chars_for_path : safe_chars =
    let a = sub_delims (Array.copy pchar) in
    (* delimiter: non-segment delimiting uses should be pct encoded *)
    a.(Char.code '/') <- false;
    a

  let safe_chars_for_query : safe_chars =
    (* TODO: What about {"!","$",","}? See <https://github.com/avsm/ocaml-uri/commit/1ef3f1dfb41bdb4f33f223ffe16e62a33975661a#diff-740f2de53c9eb36e9670ddfbdb9ba914R171> *)
    let a = Array.copy pchar in
    a.(Char.code '/') <- true;
    a.(Char.code '?') <- true;
    (* '&' is safe but we should encode literals to avoid ambiguity
       with the already parsed qs params *)
    a.(Char.code '&') <- false;
    (* ';' is safe but some systems treat it like '&'. *)
    a.(Char.code ';') <- false;
    a.(Char.code '+') <- false;
    a

  let safe_chars_for_query_key : safe_chars =
    let a = Array.copy safe_chars_for_query in
    a.(Char.code '=') <- false;
    a

  let safe_chars_for_query_value : safe_chars =
    let a = Array.copy safe_chars_for_query in
    a.(Char.code ',') <- false;
    a

  let safe_chars_for_fragment : safe_chars = safe_chars_for_query

  (** Safe characters for the userinfo subcomponent of a URI.
      TODO: this needs more reserved characters added *)
  let safe_chars_for_userinfo : safe_chars =
    let a = Array.copy safe_chars in
    (* delimiter: non-segment delimiting uses should be pct encoded *)
    a.(Char.code ':') <- false;
    a

  let rec safe_chars_for_component = function
    | `Path -> safe_chars_for_path
    | `Userinfo -> safe_chars_for_userinfo
    | `Query -> safe_chars_for_query
    | `Query_key -> safe_chars_for_query_key
    | `Query_value -> safe_chars_for_query_value
    | `Fragment -> safe_chars_for_fragment
    | `Scheme -> safe_chars_for_scheme
    | `Custom ((component : component), safe, unsafe) ->
       let safe_chars = Array.copy (safe_chars_for_component component) in
       for i = 0 to String.length safe - 1 do
         let c = Char.code safe.[i] in
         safe_chars.(c) <- true
       done;
       for i = 0 to String.length unsafe - 1 do
         let c = Char.code unsafe.[i] in
         safe_chars.(c) <- false
       done;
       safe_chars
    | `Generic
    | _ -> safe_chars

  let normalize_host hso = hso

  let canonicalize_port port = port
  let canonicalize_path path = path
end

module Http : Scheme = struct
  include Generic

  let normalize_host = function
    | Some hs -> Some (String.lowercase_ascii hs)
    | None -> None

  let canonicalize_port = function
    | None -> None
    | Some 80 -> None
    | Some x -> Some x

  let canonicalize_path = function
    | [] -> ["/"]
    | x  -> x
end

module Https : Scheme = struct
  include Http

  let canonicalize_port = function
    | None -> None
    | Some 443 -> None
    | Some x -> Some x
end

module File : Scheme = struct
  include Generic

  let normalize_host = function
    | Some hs ->
      let hs = String.lowercase_ascii hs in
      if hs="localhost" then Some "" else Some hs
    | None -> None
end

module Urn : Scheme = struct
  include Generic

end

let module_of_scheme = function
  | Some s -> begin match String.lowercase_ascii s with
      | "http" -> (module Http : Scheme)
      | "https"  -> (module Https : Scheme)
      | "file" -> (module File : Scheme)
      | "urn"  -> (module Urn : Scheme)
      | _ -> (module Generic : Scheme)
    end
  | None -> (module Generic : Scheme)

(** Portions of the URL must be converted to-and-from percent-encoding
  * and this really, really shouldn't be mixed up. So this Pct module
  * defines abstract Pct.encoded and Pct.decoded types which sets the
  * state of the underlying string.  There are functions to "cast" to
  * and from these and normal strings, and this promotes a bit of
  * internal safety.  These types are not exposed to the external
  * interface, as casting to-and-from is quite a bit of hassle and
  * probably not a lot of use to the average consumer of this library
*)
module Pct : sig
  type encoded
  type decoded

  val encode : ?scheme:string -> ?component:component -> decoded -> encoded
  val decode : encoded -> decoded

  (* The empty decoded string *)
  val empty_decoded : decoded
  (* Identity functions so we need to explicitly cast when using them below *)
  val cast_encoded : string -> encoded
  val cast_decoded : string -> decoded
  val uncast_encoded : encoded -> string
  val uncast_decoded : decoded -> string
  (* Lift HOFs for maps over encodings, decodings, and strings *)
  val lift_encoded : (encoded -> encoded) -> string -> string
  val lift_decoded : (decoded -> decoded) -> string -> string
  val unlift_encoded : (string -> string) -> encoded -> encoded
  val unlift_decoded : (string -> string) -> decoded -> decoded
  val unlift_decoded2 : (string -> string -> 'a) -> decoded -> decoded -> 'a
end = struct
  type encoded = string
  type decoded = string
  let cast_encoded x = x
  let cast_decoded x = x
  let empty_decoded = ""
  let uncast_decoded x = x
  let uncast_encoded x = x

  let lift_encoded f = f
  let lift_decoded f = f
  let unlift_encoded f = f
  let unlift_decoded f = f
  let unlift_decoded2 f = f

  (** Scan for reserved characters and replace them with
      percent-encoded equivalents.
      @return a percent-encoded string *)
  let encode ?scheme ?(component=`Path) b =
    let module Scheme = (val (module_of_scheme scheme) : Scheme) in
    let safe_chars = Scheme.safe_chars_for_component component in
    let len = String.length b in
    let buf = Buffer.create len in
    let rec scan start cur =
      if cur >= len then begin
        Buffer.add_substring buf b start (cur-start);
      end else begin
        let c = Char.code b.[cur] in
        if safe_chars.(c) then
          scan start (cur+1)
        else begin
          if cur > start then Buffer.add_substring buf b start (cur-start);
          Buffer.add_string buf (Printf.sprintf "%%%02X" c);
          scan (cur+1) (cur+1)
        end
      end
    in
    scan 0 0;
    Buffer.contents buf

  let int_of_hex_char c =
    let c = int_of_char (Char.uppercase_ascii c) - 48 in
    if c > 9
    then if c > 16 && c < 23
      then c - 7
      else failwith "int_of_hex_char"
    else if c >= 0
    then c
    else failwith "int_of_hex_char"

  (** Scan for percent-encoding and convert them into ASCII.
      @return a percent-decoded string *)
  let decode b =
    (* TODO: Should both strict and non-strict versions be exposed? *)
    let len = String.length b in
    let buf = Buffer.create len in
    let rec scan start cur =
      if cur >= len then Buffer.add_substring buf b start (cur-start)
      else if b.[cur] = '%' then begin
        Buffer.add_substring buf b start (cur-start);
        let cur = cur + 1 in
        if cur >= len then Buffer.add_char buf '%'
        else match int_of_hex_char b.[cur] with
        | exception _ ->
          Buffer.add_char buf '%';
          scan cur cur
        | highbits -> begin
          let cur = cur + 1 in
          if cur >= len then begin
            Buffer.add_char buf '%';
            Buffer.add_char buf b.[cur-1]
          end else begin
            let start_at =
              match int_of_hex_char b.[cur] with
              | lowbits ->
                Buffer.add_char buf (Char.chr (highbits lsl 4 + lowbits));
                cur+1
              | exception _ ->
                Buffer.add_char buf '%';
                Buffer.add_char buf b.[cur-1];
                cur
            in scan start_at start_at
          end
        end
      end else scan start (cur+1)
    in
    scan 0 0;
    Buffer.contents buf
end

(* Percent encode a string *)
let pct_encode ?scheme ?(component=`Path) s =
  Pct.(uncast_encoded (encode ?scheme ~component (cast_decoded s)))

let pct_encoder
      ?(scheme=`Scheme)
      ?(userinfo=`Userinfo)
      ?(host=`Host)
      ?(path=`Path)
      ?(query_key=`Query_key)
      ?(query_value=`Query_value)
      ?(fragment=`Fragment)
      () =
  { scheme; userinfo; host; path; query_key; query_value; fragment }

(* Percent decode a string *)
let pct_decode s = Pct.(uncast_decoded (decode (cast_encoded s)))

(* Userinfo string handling, to and from an id * credential pair *)
module Userinfo = struct
  type t = string * string option

  let compare (u,p) (u',p') =
    match String.compare u u' with
    | 0 -> compare_opt String.compare p p'
    | c -> c

  let userinfo_of_encoded us =
    match Stringext.split ~max:2 ~on:':' us with
    | [] -> ("",None)
    | [u] -> (pct_decode u,None)
    | u::p::_ -> (pct_decode u,Some (pct_decode p))

  let encoded_of_userinfo ?scheme ~component (u,po) =
    let len = String.(
      1 + (length u) + (match po with None -> 0 | Some p -> length p))
    in
    let buf = Buffer.create len in
    Buffer.add_string buf (pct_encode ?scheme ~component u);
    begin match po with None -> ();
    | Some p ->
      Buffer.add_char buf ':';
      Buffer.add_string buf (pct_encode ?scheme ~component p)
    end;
    Pct.cast_encoded (Buffer.contents buf)
end

let userinfo_of_encoded = Userinfo.userinfo_of_encoded
let encoded_of_userinfo ?scheme ~component = Userinfo.encoded_of_userinfo ?scheme ~component

(* Path string handling, to and from a list of path tokens *)
module Path = struct
  (* Invariant: every element is non-zero, slashes (/) only occur alone. *)
  (* Yes, it's better this way. This means you can retain separator
     context in recursion (e.g. remove_dot_segments for relative resolution). *)

  type t = string list

  let compare = compare_list String.compare

  (* Make a path token list from a percent-encoded string *)
  let path_of_encoded ps =
    let tokl = Stringext.full_split ps ~on:'/' in
    List.map pct_decode tokl

  (* Subroutine for resolve <http://tools.ietf.org/html/rfc3986#section-5.2.4> *)
  let remove_dot_segments p =
    let revp = List.rev p in
    let rec loop ascension outp = function
      | "/"::".."::r | ".."::r -> loop (ascension + 1) outp r
      | "/"::"."::r  | "."::r  -> loop ascension outp r
      | "/"::[] | [] when List.(length p > 0 && hd p = "/") -> "/"::outp
      | [] when ascension > 0 -> List.rev_append
        ("/"::(rev_interject "/" Array.(to_list (make ascension "..")))) outp
      | [] -> List.(if length outp > 0 && hd outp = "/" then tl outp else outp)
      | "/"::"/"::r when ascension > 0 -> loop (ascension - 1) outp ("/"::r)
      | "/"::_::r when ascension > 0 -> loop (ascension - 1) outp r
      | s::r -> loop 0 (s::outp) r
    in loop 0 [] revp

  let encoded_of_path ?scheme ~component p =
    let len = List.fold_left (fun c tok -> String.length tok + c) 0 p in
    let buf = Buffer.create len in
    iter_concat (fun buf -> function
    | "/" -> Buffer.add_char buf '/'
    | seg -> Buffer.add_string buf (pct_encode ?scheme ~component seg)
    ) "" buf p;
    Pct.cast_encoded (Buffer.contents buf)

  (* Subroutine for resolve <http://tools.ietf.org/html/rfc3986#section-5.2.3> *)
  let merge bhost bpath relpath =
    match bhost, List.rev bpath with
    | Some _, [] -> "/"::relpath
    | _, ("/"::rbpath | _::"/"::rbpath) -> List.rev_append ("/"::rbpath) relpath
    | _, _ -> relpath
end

let path_of_encoded = Path.path_of_encoded
let encoded_of_path ?scheme ~component = Path.encoded_of_path ?scheme ~component

(* Query string handling, to and from an assoc list of key/values *)
module Query = struct

  type kv = (string * string list) list

  type t =
    | KV of kv
    | Raw of string option * kv Lazy.t

  let compare x y = match x, y with
    | KV kvl, KV kvl'
    | Raw (_, lazy kvl), KV kvl'
    | KV kvl, Raw (_, lazy kvl') ->
      compare_list (fun (k,vl) (k',vl') ->
        match String.compare k k' with
        | 0 -> compare_list String.compare vl vl'
        | c -> c
      ) kvl kvl'
    | Raw (raw,_), Raw (raw',_) -> compare_opt String.compare raw raw'

  let find q k = try Some (List.assoc k q) with Not_found -> None

  let split_query qs =
    let els = Stringext.split ~on:'&' qs in
    (* Replace a + in a query string with a space in-place *)
    let plus_to_space s =
      let s = Bytes.unsafe_of_string s in
      for i = 0 to Bytes.length s - 1 do
        if Bytes.get s i = '+' then Bytes.set s i ' '
      done;
      Bytes.unsafe_to_string s
    in
    let rec loop acc = function
      | (k::v::_)::tl ->
        let n = plus_to_space k,
                (match Stringext.split ~on:',' (plus_to_space v) with
                 | [] -> [""] | l -> l) in
        loop (n::acc) tl
      | [k]::tl ->
        let n = plus_to_space k, [] in
        loop (n::acc) tl
      | []::tl -> loop (("", [])::acc) tl
      | [] -> acc
    in
    match els with
    | []  -> ["",[]]
    | els -> loop []
      (List.rev_map (fun el -> Stringext.split ~on:'=' el ~max:2) els)

  (* Make a query tuple list from a percent-encoded string *)
  let query_of_encoded qs =
    List.map
      (fun (k, v) -> (pct_decode k, List.map pct_decode v))
      (split_query qs)

  (* Assemble a query string suitable for putting into a URI.
   * Tuple inputs are percent decoded and will be encoded by
   * this function.
  *)
  let encoded_of_query ?scheme ?(pct_encoder=pct_encoder ()) l =
    let len = List.fold_left (fun a (k,v) ->
        a + (String.length k)
        + (List.fold_left (fun a s -> a+(String.length s)+1) 0 v) + 2) (-1) l in
    let buf = Buffer.create len in
    iter_concat (fun buf (k,v) ->
        Buffer.add_string buf (pct_encode ?scheme ~component:pct_encoder.query_key k);
        if v <> [] then (
          Buffer.add_char buf '=';
          iter_concat (fun buf s ->
              Buffer.add_string buf
                (pct_encode ?scheme ~component:pct_encoder.query_value s)
            ) "," buf v)
      ) "&" buf l;
    Buffer.contents buf

  let of_raw qs =
    let lazy_query = Lazy.from_fun (fun () -> query_of_encoded qs) in
    Raw (Some qs, lazy_query)

  let kv = function Raw (_, lazy kv) | KV kv -> kv
end

let query_of_encoded = Query.query_of_encoded
let encoded_of_query ?scheme = Query.encoded_of_query ?scheme

(* Type of the URI, with most bits being optional *)
type t = {
  scheme: Pct.decoded option;
  userinfo: Userinfo.t option;
  host: Pct.decoded option;
  port: int option;
  path: Path.t;
  query: Query.t;
  fragment: Pct.decoded option;
}

let empty = {
  scheme = None;
  userinfo = None;
  host = None;
  port = None;
  path = [];
  query = Query.Raw (None, Lazy.from_val []);
  fragment = None;
}

let compare_decoded = Pct.unlift_decoded2 String.compare
let compare_decoded_opt = compare_opt compare_decoded
let compare t t' =
  (match compare_decoded_opt t.host t'.host with
  | 0 -> (match compare_decoded_opt t.scheme t'.scheme with
    | 0 -> (match compare_opt (fun p p' ->
      if p < p' then -1 else if p > p' then 1 else 0
    ) t.port t'.port with
      | 0 -> (match compare_opt Userinfo.compare t.userinfo t'.userinfo with
        | 0 -> (match Path.compare t.path t'.path with
          | 0 -> (match Query.compare t.query t'.query with
            | 0 -> compare_decoded_opt t.fragment t'.fragment
            | c -> c)
          | c -> c)
        | c -> c)
      | c -> c)
    | c -> c)
  | c -> c)

let equal t t' = compare t t' = 0

let uncast_opt = function
  | Some h -> Some (Pct.uncast_decoded h)
  | None -> None

let cast_opt = function
  | Some h -> Some (Pct.cast_decoded h)
  | None -> None

let normalize schem uri =
  let module Scheme =
    (val (module_of_scheme (uncast_opt schem)) : Scheme) in
  let dob f = function
    | Some x -> Some (Pct.unlift_decoded f x)
    | None -> None
  in {uri with
      scheme=dob String.lowercase_ascii uri.scheme;
      host=cast_opt (Scheme.normalize_host (uncast_opt uri.host))
     }

(* Make a URI record. This is a bit more inefficient than it needs to be due to the
 * casting/uncasting (which isn't fully identity due to the option box), but it is
 * no big deal for now.
*)
let make ?scheme ?userinfo ?host ?port ?path ?query ?fragment () =
  let decode = function
    |Some x -> Some (Pct.cast_decoded x) |None -> None in
  let host = match userinfo, host, port with
    | _, Some _, _ | None, None, None -> host
    | Some _, None, _ | _, None, Some _ -> Some ""
  in
  let userinfo = match userinfo with
    | None -> None | Some u -> Some (userinfo_of_encoded u) in
  let path = match path with
    |None -> [] | Some p ->
      let path = path_of_encoded p in
      match host, path with
      | None, _ | Some _, "/"::_ | Some _, [] -> path
      | Some _, _  -> "/"::path
  in
  let query = match query with
    | None -> Query.KV []
    | Some p -> Query.KV p
  in
  let scheme = decode scheme in
  normalize scheme
    { scheme; userinfo;
      host=decode host; port; path; query; fragment=decode fragment }

(** Convert a URI structure into a percent-encoded string
    <http://tools.ietf.org/html/rfc3986#section-5.3>
*)
let to_string ?(pct_encoder=pct_encoder ()) uri =
  let scheme = match uri.scheme with
    | Some s -> Some (Pct.uncast_decoded s)
    | None -> None in
  let buf = Buffer.create 128 in
  (* Percent encode a decoded string and add it to the buffer *)
  let add_pct_string ?(component=`Path) x =
    Buffer.add_string buf (Pct.uncast_encoded (Pct.encode ?scheme ~component x))
  in
  (match uri.scheme with
   |None -> ()
   |Some x ->
     add_pct_string ~component:pct_encoder.scheme x;
     Buffer.add_char buf ':'
  );
  (* URI has a host if any host-related component is set. Defaults to "". *)
  if (match uri.userinfo, uri.host, uri.port with
  | Some _, _, _ | _, Some _, _ | _, _, Some _ -> true | _ -> false)
  then Buffer.add_string buf "//";
  (match uri.userinfo with
  |None -> ()
  |Some userinfo ->
    Buffer.add_string buf
      (Pct.uncast_encoded (encoded_of_userinfo ?scheme ~component:pct_encoder.userinfo userinfo));
    Buffer.add_char buf '@'
  );
  (match uri.host with
  |None -> ()
  |Some host ->
    add_pct_string ~component:pct_encoder.host host;
  );
  (match uri.port with
  |None -> ()
  |Some port ->
    Buffer.add_char buf ':';
    Buffer.add_string buf (string_of_int port)
  );
  (match uri.path with (* Handle relative paths correctly *)
  | [] -> ()
  | "/"::_ ->
    Buffer.add_string buf (Pct.uncast_encoded
                              (encoded_of_path ?scheme ~component:pct_encoder.path uri.path))
  | first_segment::_ ->
    (match uri.host with
     | Some _ -> Buffer.add_char buf '/'
     | None ->
       (* ensure roundtrip by forcing relative path interpretation not scheme *)
       match Stringext.find_from first_segment ~pattern:":" with
       | None -> ()
       | Some _ -> match scheme with
         | Some _ -> ()
         | None -> Buffer.add_string buf "./"
    );
    Buffer.add_string buf
      (Pct.uncast_encoded (encoded_of_path ?scheme ~component:pct_encoder.path uri.path))
  );
  Query.(match uri.query with
    | Raw (None,_) | KV [] -> ()
    | Raw (_,lazy q) | KV q -> (* normalize e.g. percent capitalization *)
      Buffer.add_char buf '?';
      Buffer.add_string buf (encoded_of_query ?scheme ~pct_encoder q)
  );
  (match uri.fragment with
   |None -> ()
   |Some f -> Buffer.add_char buf '#'; add_pct_string ~component:pct_encoder.fragment f
  );
  Buffer.contents buf

(* Various accessor functions, as the external uri type is abstract  *)
let get_decoded_opt = function None -> None |Some x -> Some (Pct.uncast_decoded x)
let scheme uri = get_decoded_opt uri.scheme
let with_scheme uri =
  function
  |Some scheme -> { uri with scheme=Some (Pct.cast_decoded scheme) }
  |None -> { uri with scheme=None }

let host uri = get_decoded_opt uri.host
let with_host uri =
  function
  |Some host -> { uri with host=Some (Pct.cast_decoded host) }
  |None -> { uri with host=None }

let host_with_default ?(default="localhost") uri =
  match host uri with
  |None -> default
  |Some h -> h

let userinfo ?(pct_encoder=pct_encoder ()) uri = match uri.userinfo with
  | None -> None
  | Some userinfo -> Some (Pct.uncast_encoded (match uri.scheme with
    | None -> encoded_of_userinfo ~component:pct_encoder.userinfo userinfo
    | Some s -> encoded_of_userinfo ~scheme:(Pct.uncast_decoded s) ~component:pct_encoder.userinfo userinfo))
let with_userinfo uri userinfo =
  let userinfo = match userinfo with
    | Some u -> Some (userinfo_of_encoded u)
    | None -> None
  in
  match host uri with
  | None -> { uri with host=Some (Pct.cast_decoded ""); userinfo=userinfo }
  | Some _ -> { uri with userinfo=userinfo }

let user uri = match uri.userinfo with
  | None -> None
  | Some (user, _) -> Some user

let password uri = match uri.userinfo with
  | None | Some (_, None) -> None
  | Some (_, Some pass) -> Some pass
let with_password uri password =
  let result userinfo = match host uri with
    | None -> { uri with host=Some (Pct.cast_decoded ""); userinfo=userinfo }
    | Some _ -> { uri with userinfo=userinfo }
  in
  match uri.userinfo, password with
  | None, None -> uri
  | None, Some _ -> result (Some ("",password))
  | Some (user,_), _ -> result (Some (user, password))

let port uri = uri.port
let with_port uri port =
  match host uri with
  | Some _ -> { uri with port=port }
  | None -> begin
     match port with
     | None -> { uri with host=None; port=None }
     | Some _ -> { uri with host=Some (Pct.cast_decoded ""); port=port }
  end

(* Return the path component *)
let path ?(pct_encoder=pct_encoder ()) uri = Pct.uncast_encoded (match uri.scheme with
  | None -> encoded_of_path ~component:pct_encoder.path uri.path
  | Some s -> encoded_of_path ~scheme:(Pct.uncast_decoded s) ~component:pct_encoder.path uri.path)
let with_path uri path =
  let path = path_of_encoded path in
  match host uri, path with
  | None, _ | Some _, "/"::_ | Some _, [] -> { uri with path=path }
  | Some _, _  -> { uri with path="/"::path }

let fragment uri = get_decoded_opt uri.fragment
let with_fragment uri =
  function
  |None -> { uri with fragment=None }
  |Some frag -> { uri with fragment=Some (Pct.cast_decoded frag) }

let query uri = Query.kv uri.query
let verbatim_query ?(pct_encoder=pct_encoder ()) uri = Query.(match uri.query with
  | Raw (qs,_) -> qs
  | KV [] -> None
  | KV kv -> Some (encoded_of_query ?scheme:(scheme uri) ~pct_encoder kv)
)
let get_query_param' uri k = Query.(find (kv uri.query) k)
let get_query_param uri k =
  match get_query_param' uri k with
  |None -> None
  |Some v -> Some (String.concat "," v)

let with_query uri query = { uri with query=Query.KV query }
let q_s q = List.map (fun (k,v) -> k,[v]) q
let with_query' uri query = with_query uri (q_s query)
let add_query_param uri p = Query.({ uri with query=KV (p::(kv uri.query)) })
let add_query_param' uri (k,v) =
  Query.({ uri with query=KV ((k,[v])::(kv uri.query)) })
let add_query_params uri ps = Query.({ uri with query=KV (ps@(kv uri.query)) })
let add_query_params' uri ps =
  Query.({ uri with query=KV ((q_s ps)@(kv uri.query)) })
let remove_query_param uri k = Query.(
  { uri with query=KV (List.filter (fun (k',_) -> k<>k') (kv uri.query)) }
)

let with_uri ?scheme ?userinfo ?host ?port ?path ?query ?fragment uri =
  let with_path_opt u o =
    match o with
    | None -> with_path u ""
    | Some p -> with_path u p
  in
  let with_query_opt u o =
    match o with
    | None -> with_query u []
    | Some q -> with_query u q
  in
  let with_ f o u =
    match o with
    | None -> u
    | Some x -> f u x
  in
  with_ with_scheme scheme uri
  |> with_ with_userinfo userinfo
  |> with_ with_host host
  |> with_ with_port port
  |> with_ with_path_opt path
  |> with_ with_query_opt query
  |> with_ with_fragment fragment

(* Construct encoded path and query components *)
let path_and_query uri =
  match (path uri), (query uri) with
  |"", [] -> "/" (* TODO: What about same document? (/) *)
  |"", q -> (* TODO: What about same document? (/) *)
    let scheme = uncast_opt uri.scheme in
    Printf.sprintf "/?%s" (encoded_of_query ?scheme q)
  |p, [] -> p
  |p, q ->
    let scheme = uncast_opt uri.scheme in
    Printf.sprintf "%s?%s" p (encoded_of_query ?scheme q)

(* TODO: functions to add and remove from a URI *)

(* Resolve a URI wrt a base URI <http://tools.ietf.org/html/rfc3986#section-5.2> *)
let resolve schem base uri =
  let schem = Some (Pct.cast_decoded (match scheme base with
      | None ->  schem
      | Some scheme -> scheme
    )) in
  normalize schem
    Path.(match scheme uri, userinfo uri, host uri with
    | Some _, _, _ ->
      {uri with path=remove_dot_segments uri.path}
    | None, Some _, _
    | None, _, Some _ ->
      {uri with scheme=base.scheme; path=remove_dot_segments uri.path}
    | None, None, None ->
      let uri = {uri with scheme=base.scheme; userinfo=base.userinfo;
                          host=base.host; port=base.port} in
      let path_str = path uri in
      if path_str=""
      then { uri with
             path=base.path;
             query=match uri.query with
               | Query.Raw (None,_) | Query.KV [] -> base.query
               | _ -> uri.query
           }
      else if path_str.[0]='/'
      then {uri with path=remove_dot_segments uri.path}
      else {uri with
        path=remove_dot_segments (merge base.host base.path uri.path);
      }
    )

let canonicalize uri =
  let uri = resolve "" empty uri in
  let module Scheme =
    (val (module_of_scheme (uncast_opt uri.scheme)) : Scheme) in
  { uri with
    port=Scheme.canonicalize_port uri.port;
    path=Scheme.canonicalize_path uri.path;
  }

let pp ppf uri = Format.pp_print_string ppf (to_string uri)
let pp_hum ppf uri = Format.pp_print_string ppf (to_string uri)

module Parser = struct
  open Angstrom

  let string_of_char = String.make 1

  let string_of_char_list chars =
    String.concat "" (List.map string_of_char chars)

  let scheme =
    lift
      (fun s -> Some (Pct.decode (Pct.cast_encoded s)))
      (take_while (fun c -> c <> ':' && c <> '/' && c <> '?' && c <> '#')
      <* char ':')
    <|> return None

  let is_digit = function '0' .. '9' -> true | _ -> false

  let hex_digit =
    satisfy (function
        | '0' .. '9' | 'A' .. 'F' | 'a' .. 'f' ->
          true
        | _ ->
          false)

  let hexadecimal = lift string_of_char_list (many hex_digit)

  let c_dot = char '.'

  let c_at = char '@'

  let c_colon = char ':'

  let dec_octet =
    take_while1 (function '0' .. '9' -> true | _ -> false) >>= fun num ->
    if int_of_string num < 256 then
      return num
    else
      fail "invalid octect"

  let ipv4_address =
    lift2
      (fun three one -> String.concat "." three ^ "." ^ one)
      (count 3 (dec_octet <* c_dot))
      dec_octet

  (* -- after double colon, IPv4 dotted notation could appear anywhere *)
  let after_double_colon =
    fix (fun f ->
        list [ ipv4_address ]
        <|> lift2 (fun x y -> x :: y) hexadecimal (c_colon *> f <|> return []))

  let double_colon count =
    after_double_colon >>= (fun rest ->
    let filler_length = 8 - count - List.length rest in
    if filler_length <= 0 then
      fail "too many parts in IPv6 address"
    else
      return ("" :: rest))
    <|> return [""]

  let rec part = function
    | 7 ->
      (* max 8 parts in an IPv6 address *)
      lift (fun x -> [ x ]) hexadecimal
    | 6 ->
      (* after 6 parts it could end in IPv4 dotted notation *)
      list [ ipv4_address ] <|> hex_part 6
    | n ->
      hex_part n

  and hex_part n =
    lift2
      (fun x y -> x :: y)
      hexadecimal
      (c_colon *> (c_colon *> double_colon (n + 1) <|> part (n + 1)))

  let rec split_with f xs =
    match xs with
    | [] ->
      [], []
    | y :: ys ->
      if f y then
        let zs, ts = split_with f ys in
        y :: zs, ts
      else
        [], xs

  let ipv6 =
    let format_addr segments =
      let before_double_colon, after_double_colon =
        split_with (fun segment -> segment <> "") segments
      in
      let before = String.concat ":" before_double_colon in
      let res =
        match after_double_colon with
        | "" :: xs ->
          before ^ "::" ^ String.concat ":" xs
        | _ ->
          before
      in
      res
    in
    lift format_addr (c_colon *> c_colon *> double_colon 0 <|> part 0)

  let ipv6_address =
    lift3
      (fun lb ip rb ->
        String.concat "" [ string_of_char lb; ip; string_of_char rb ])
      (char '[')
      ipv6
      (char ']')

  let pct_encoded =
    lift2
      (fun pct digits -> string_of_char_list (pct :: digits))
      (char '%')
      (count 2 hex_digit)

  let sub_delims =
    satisfy (function
        | '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' ->
          true
        | _ ->
          false)

  let unreserved =
    (* "[A-Za-z0-9-._~]" *)
    satisfy (function
        | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '-' | '.' | '_' | '~' ->
          true
        | _ ->
          false)

  let reg_name =
    lift
      (String.concat "")
      (many
         (choice
            [ string_of_char <$> unreserved
            ; pct_encoded
            ; string_of_char <$> sub_delims
            ]))

  let host =
    lift
      (fun s -> Pct.decode (Pct.cast_encoded s))
      (choice
         [ reg_name; ipv4_address; ipv6_address (* | ipv4_literal TODO *) ])

  let userinfo =
    lift
      (fun x ->
        let s = String.concat "" x in
        Some (Userinfo.userinfo_of_encoded s))
      (many
         (choice
            [ string_of_char <$> unreserved
            ; pct_encoded
            ; string_of_char <$> sub_delims
            ; string_of_char <$> c_colon
            ])
      <* c_at)
    <|> return None

  let port =
    peek_char >>= function
    | Some ':' ->
      c_colon *> take_while is_digit >>| fun port ->
      let decoded = Pct.decode (Pct.cast_encoded port) in
      (try Some (int_of_string (Pct.uncast_decoded decoded)) with _ -> None)
    | Some _ | None ->
      return None

  let authority =
    string "//"
    *> lift3
         (fun userinfo host port -> userinfo, Some host, port)
         userinfo
         host
         port
    <|> return (None, None, None)

  let path =
    lift
      Path.path_of_encoded
      (take_while (function '?' | '#' -> false | _ -> true))

  let query =
    lift
      Query.of_raw
      (char '?' *> take_till (function '#' -> true | _ -> false))
    <|> return (Query.Raw (None, Lazy.from_val []))

  let fragment =
    lift
      (fun s -> Some (Pct.decode (Pct.cast_encoded s)))
      (char '#' *> take_while (fun _ -> true))
    <|> return None

  let _uri_reference =
    lift4
      (fun scheme (userinfo, host, port) path query fragment ->
        normalize scheme { scheme; userinfo; host; port; path; query; fragment })
      scheme
      authority
      path
      query
    <*> fragment

  (* XXX(anmonteiro): For compatibility reasons with the old regex parser, we
   * only parse until the first newline character and drop everything else
   * after that *)
  let uri_reference =
    take_while (function | '\n' -> false | _ -> true) >>| fun s ->
      match Angstrom.parse_string ~consume:All _uri_reference s with
      | Ok t -> t
      | Error _ ->
        (* Shouldn't really happen if the parser is forgiving. *)
        empty
end

let of_string s =
  (* To preserve the old regex parser's behavior, we only parse a prefix, and
   * stop whenever we can't parse more. *)
  match Angstrom.parse_string ~consume:Prefix Parser.uri_reference s with
  | Ok t -> t
  | Error _ ->
    (* Shouldn't really happen if the parser is forgiving. *)
    empty

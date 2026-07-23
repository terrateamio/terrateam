(*{{{ Copyright (C) 2015 Trevor Smith <trevorsummerssmith@gmail.com>
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

(** This example is here to show how to get and put to s3 using the async client
    code.

    This hopes to be a useful example because: 1) it is a real world use of the
    client 2) s3 auth requires a bit of fiddling with the headers hopefully this
    is illustative for anyone else doing the same

    The reader will want to be familiar with the S3 API Documentation found
    here: http://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html This
    example was written using the API Version 2006-03-01.

    There are two ways to authenticate with S3, this example uses the
    authorization header approach (p. 19 of the api reference).

    Downloads from S3 are done using the GET method, and uploads are done using
    the PUT method.

    To get this to work, you'll need an AWS access/secret key pair that has the
    "s3:GetObject" and "s3:PutObject" permissions enabled for the bucket you are
    interacting with.

    As this is an example, straightforwardness is prized. One should not use
    this for a production system, nor assume that it offers a good example of
    abstraction, interface design or error handling. *)

open Base
open Core
open Async
open Cohttp
open Cohttp_async

module Time = Time_float

let ksrt (k, _) (k', _) = String.compare k k'

module Compat = struct
  (** Things we need to make this happen that, ideally, we'd like other
      libraries to provide and that are orthogonal to the example here *)

  let encode_string s =
    (* Percent encode the path as s3 wants it. Uri doesn't
       encode $, or the other sep characters in a path.
       If upstream allows that we can nix this function *)
    let n = String.length s in
    let buf = Buffer.create (n * 3) in
    for i = 0 to n - 1 do
      let c = s.[i] in
      match c with
      | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '~' | '.' | '/' ->
          Buffer.add_char buf c
      | '%' ->
          (* Sigh. Annoying we're expecting already escaped strings so ignore the escapes *)
          let is_hex = function
            | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' -> true
            | _ -> false
          in
          if i + 2 < n then
            if is_hex s.[i + 1] && is_hex s.[i + 2] then Buffer.add_char buf c
            else Buffer.add_string buf "%25"
      | _ -> Buffer.add_string buf (Printf.sprintf "%%%X" (Char.to_int c))
    done;
    Buffer.contents buf

  let hexa = "0123456789abcdef"

  let of_char c =
    let x = Char.to_int c in
    (hexa.[x lsr 4], hexa.[x land 0xf])

  let cstruct_to_hex_string cs =
    let open Cstruct in
    let n = cs.len in
    let buf = Buffer.create (n * 2) in
    for i = 0 to n - 1 do
      let c = cs.buffer.{cs.off + i} in
      let x, y = of_char c in
      Buffer.add_char buf x;
      Buffer.add_char buf y
    done;
    Buffer.contents buf

  let encode_query_string uri =
    (* Sort and encode query string.
       Note that AWS wants null keys to have '=' for all keys.
       URI.encoded_of_query encodes [""] as ?a=, and [] as ?a.
    *)
    Uri.query uri
    |> List.sort ~compare:ksrt
    |> List.map ~f:(fun (k, v) -> (k, match v with [] -> [ "" ] | x -> x))
    |> Uri.encoded_of_query

  let format_time t =
    (* Core.Std.Time doesn't have a format function that takes a timezone *)
    let d, s = Time.to_date_ofday ~zone:Time.Zone.utc t in
    let open Time.Span.Parts in
    let { hr; min; sec; _ } = Time.Ofday.to_parts s in
    Printf.sprintf "%sT%.2d%.2d%.2dZ"
      (Date.to_string_iso8601_basic d)
      hr min sec
end

type region =
  [ `Ap_northeast_1 (* Asia Pacific (Tokyo) *)
  | `Ap_southeast_1 (* Asia Pacific (Singapore) *)
  | `Ap_southeast_2 (* Asia Pacific (Sydney) *)
  | `Eu_central_1 (* EU (Frankfurt) *)
  | `Eu_west_1 (* EU (Ireland) *)
  | `Sa_east_1 (* South America (Sao Paulo) *)
  | `Us_east_1 (* US East (N. Virginia) *)
  | `Us_west_1 (* US West (N. California) *)
  | `Us_west_2 (* US West (Oregon) *) ]
[@@deriving sexp]

let region_of_string = function
  | "ap-northeast-1" -> `Ap_northeast_1
  | "ap-southeast-1" -> `Ap_southeast_1
  | "ap-southeast-2" -> `Ap_southeast_2
  | "eu-central-1" -> `Eu_central_1
  | "eu-west-1" -> `Eu_west_1
  | "sa-east-1" -> `Sa_east_1
  | "us-east-1" -> `Us_east_1
  | "us-west-1" -> `Us_west_1
  | "us-west-2" -> `Us_west_2
  | s -> raise (Invalid_argument ("region_of_string: " ^ s))

let string_of_region = function
  | `Ap_northeast_1 -> "ap-northeast-1"
  | `Ap_southeast_1 -> "ap-southeast-1"
  | `Ap_southeast_2 -> "ap-southeast-2"
  | `Eu_central_1 -> "eu-central-1"
  | `Eu_west_1 -> "eu-west-1"
  | `Sa_east_1 -> "sa-east-1"
  | `Us_east_1 -> "us-east-1"
  | `Us_west_1 -> "us-west-1"
  | `Us_west_2 -> "us-west-2"

let region_host_string = function
  | `Ap_northeast_1 -> "s3-ap-northeast-1.amazonaws.com"
  | `Ap_southeast_1 -> "s3-ap-southeast-1.amazonaws.com"
  | `Ap_southeast_2 -> "s3-ap-southeast-2.amazonaws.com"
  | `Eu_central_1 -> "s3-eu-central-1.amazonaws.com"
  | `Eu_west_1 -> "s3-eu-west-1.amazonaws.com"
  | `Sa_east_1 -> "s3-sa-east-1.amazonaws.com"
  | `Us_east_1 -> "s3.amazonaws.com"
  | `Us_west_1 -> "s3-us-west-1.amazonaws.com"
  | `Us_west_2 -> "s3-us-west-2.amazonaws.com"

type service = [ `S3 ] [@@deriving sexp]

let string_of_service = function `S3 -> "s3"

module Auth = struct
  (** AWS S3 Authorization *)

  let digest s =
    (* string -> sha256 as a hex string *)
    Mirage_crypto.Hash.(digest `SHA256 (Cstruct.of_string s))
    |> Compat.cstruct_to_hex_string

  let make_amz_headers ?body time =
    (* Return x-amz-date and x-amz-sha256 headers *)
    let hashed_payload =
      match body with
      | None ->
          "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
      | Some s -> digest s
    in
    ( [
        ("x-amz-content-sha256", hashed_payload);
        ("x-amz-date", Compat.format_time time);
      ],
      hashed_payload )

  let canonical_request hashed_payload (request : Cohttp_async.Request.t) =
    (* This corresponds to p.21 of the s3 api doc
       we're making:
       <HTTPMethod>\n
       <CanonicalURI>\n
       <CanonicalQueryString>\n
       <CanonicalHeaders>\n
       <SignedHeaders>\n
       <HashedPayload>
    *)
    let open Cohttp.Request in
    let http_method = Code.string_of_method request.meth in
    (* Nb the path will be url encoded as per spec *)
    let uri = Cohttp.Request.uri request in
    let canoncical_uri = Compat.encode_string (Uri.path uri) in
    (* Sort query string in alphabetical order by key *)
    let canonical_query = Compat.encode_query_string uri in
    let sorted_headers =
      Header.to_list request.headers |> List.sort ~compare:ksrt
    in
    let canonical_headers =
      sorted_headers
      |> List.fold ~init:"" ~f:(fun acc (k, v) ->
             acc
             ^ Printf.sprintf "%s:%s\n" (String.lowercase k) (String.strip v))
    in
    let signed_headers =
      sorted_headers |> List.map ~f:(fun (k, _) -> k) |> String.concat ~sep:";"
    in
    ( Printf.sprintf "%s\n%s\n%s\n%s\n%s\n%s" http_method canoncical_uri
        canonical_query canonical_headers signed_headers hashed_payload,
      signed_headers )

  let string_to_sign ?time ~scope ~service canonical_request : string =
    (* As per p. 23 of s3 api doc. The requests need current time in utc
       time parameter is there for testing. *)
    let time_str =
      match time with
      | None -> Time.to_string_abs ~zone:Time.Zone.utc (Time.now ())
      | Some t -> Compat.format_time t
    in
    let scope_date, scope_region = scope in
    let scope_str =
      Printf.sprintf "%s/%s/%s/aws4_request"
        (Date.to_string_iso8601_basic scope_date)
        (string_of_region scope_region)
        (string_of_service service)
    in
    let hashed_req = digest canonical_request in
    Printf.sprintf "AWS4-HMAC-SHA256\n%s\n%s\n%s" time_str scope_str hashed_req

  let make_signing_key ?date ~region ~service ~secret_access_key () =
    let mac k v =
      Mirage_crypto.Hash.(mac `SHA256 ~key:k (Cstruct.of_string v))
    in
    let date' =
      match date with None -> Date.today ~zone:Time.Zone.utc | Some d -> d
    in
    let date_str = Date.to_string_iso8601_basic date' in
    let date_key =
      mac (Cstruct.of_string ("AWS4" ^ secret_access_key)) date_str
    in
    let date_region_key = mac date_key (string_of_region region) in
    let date_region_service_key =
      mac date_region_key (string_of_service service)
    in
    let signing_key = mac date_region_service_key "aws4_request" in
    signing_key

  let auth_request ?now ~hashed_payload ~region ~service ~aws_access_key
      ~aws_secret_key request =
    (* Important use the same time for everything here *)
    let time = Option.value ~default:(Time.now ()) now in
    let date = Time.to_date ~zone:Time.Zone.utc time in
    let canonical_request, signed_headers =
      canonical_request hashed_payload request
    in
    let string_to_sign =
      string_to_sign ~time ~scope:(date, region) ~service canonical_request
    in
    let signing_key =
      make_signing_key ~date ~region ~service ~secret_access_key:aws_secret_key
        ()
    in
    let creds =
      Printf.sprintf "%s/%s/%s/%s/aws4_request" aws_access_key
        (Date.to_string_iso8601_basic date)
        (string_of_region region)
        (string_of_service service)
    in
    let signature =
      Mirage_crypto.Hash.(
        mac `SHA256 ~key:signing_key (Cstruct.of_string string_to_sign))
    in
    let auth_header =
      Printf.sprintf
        "AWS4-HMAC-SHA256 Credential=%s,SignedHeaders=%s,Signature=%s" creds
        signed_headers
        (Compat.cstruct_to_hex_string signature)
    in
    [ ("Authorization", auth_header) ]
end

module S3 = struct
  type conf = {
    region : region;
    aws_access_key : string;
    aws_secret_key : string;
  }
  [@@deriving sexp]

  let make_request ?body conf ~meth ~bucket ~objekt =
    let host_str = region_host_string conf.region in
    let uri =
      Printf.sprintf "https://%s/%s/%s" host_str bucket objekt |> Uri.of_string
    in
    let time = Time.now () in
    (* If PUT add content length *)
    let headers =
      match meth with
      | `PUT ->
          let length = Option.value_map ~f:String.length ~default:0 body in
          [ ("Content-length", Int.to_string length) ]
      | _ -> []
    in
    let headers = headers @ [ ("Host", host_str) ] in
    let amz_headers, hashed_payload = Auth.make_amz_headers time ?body in
    let headers = headers @ amz_headers in
    let request = Request.make ~meth ~headers:(Header.of_list headers) uri in
    let auth_header =
      Auth.auth_request ~now:time ~hashed_payload ~region:conf.region
        ~service:`S3 ~aws_access_key:conf.aws_access_key
        ~aws_secret_key:conf.aws_secret_key request
    in
    let headers = headers @ auth_header |> Header.of_list in
    let request = { request with Cohttp.Request.headers } in
    match meth with
    | `PUT ->
        Client.request
          ~body:(Option.value_map ~f:Body.of_string ~default:`Empty body)
          request
    | `GET -> Client.request request
    | _ -> failwith "not possible right now"
end

type s3path = { bucket : string; objekt : string }
type cmd = S3toLocal of s3path * string | LocaltoS3 of string * s3path

let determine_s3_parts s =
  (* Takes: string of the form s3://<bucket>/<object> *)
  let s = String.drop_prefix s 5 in
  let parts = String.split ~on:'/' s in
  match parts with
  | bucket :: rst -> { bucket; objekt = String.concat ~sep:"/" rst }
  | _ -> failwith "error format must be 's3://<bucket>/<object>'"

let determine_paths src dst =
  let is_s3 s = String.is_prefix ~prefix:"s3://" s in
  match (is_s3 src, is_s3 dst) with
  | true, false -> S3toLocal (determine_s3_parts src, dst)
  | false, true -> LocaltoS3 (src, determine_s3_parts dst)
  | false, false -> failwith "Use cp(1) :)"
  | true, true -> failwith "Does not support copying from s3 to s3"

let main region_str aws_access_key aws_secret_key src dst () =
  (* nb client does not support redirects or preflight 100 *)
  let open S3 in
  let region = region_of_string region_str in
  let conf = { region; aws_access_key; aws_secret_key } in
  match determine_paths src dst with
  | S3toLocal (src, dst) -> (
      make_request conf ~meth:`GET ~bucket:src.bucket ~objekt:src.objekt
      >>= fun (resp, body) ->
      match Cohttp.Response.(resp.status) with
      | #Code.success_status ->
          Body.to_string body >>| fun s ->
          Out_channel.with_file
            ~f:(fun oc -> Out_channel.output_string oc s)
            dst;
          Core.Printf.printf "Wrote s3://%s to %s\n" (src.bucket ^ src.objekt)
            dst
      | _ ->
          Core.Printf.printf "Error: %s\n"
            (Sexp.to_string (Response.sexp_of_t resp));
          return ())
  | LocaltoS3 (src, dst) -> (
      let body =
        In_channel.with_file src ~f:(fun ic -> In_channel.input_all ic)
      in
      make_request ~body conf ~meth:`PUT ~bucket:dst.bucket ~objekt:dst.objekt
      >>= fun (resp, body) ->
      match Cohttp.Response.status resp with
      | #Code.success_status ->
          Core.Printf.printf "Wrote %s to s3://%s\n" src
            (dst.bucket ^ dst.objekt);
          return ()
      | _ ->
          Body.to_string body >>| fun s ->
          Core.Printf.printf "Error: %s\n%s\n"
            (Sexp.to_string (Response.sexp_of_t resp))
            s)

let () =
  let open Async_command in
  async_spec ~summary:"Simple command line client that copies files to/from S3"
    Spec.(
      empty
      +> flag "-r"
           (optional_with_default "us-east-1" string)
           ~doc:"string AWS Region"
      +> anon ("aws_access_key" %: string)
      +> anon ("aws_secret_key" %: string)
      +> anon ("src" %: string)
      +> anon ("dst" %: string))
    main
  |> Command_unix.run

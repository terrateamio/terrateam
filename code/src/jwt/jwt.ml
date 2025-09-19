module Verifier = struct
  let z_of_string s =
    s
    |> Base64.decode_exn ~pad:false ~alphabet:Base64.uri_safe_alphabet
    |> CCString.to_list
    |> CCList.map (fun c -> Printf.sprintf "%02x" (Char.code c))
    |> CCString.concat ""
    |> Z.of_string_base 16

  module Pub_key = struct
    type t = Mirage_crypto_pk.Rsa.pub

    let create ~e ~n =
      CCOption.wrap
        (fun () ->
          let e = z_of_string e in
          let n = z_of_string n in
          (* TODO: Handle errors *)
          CCResult.get_exn (Mirage_crypto_pk.Rsa.pub ~e ~n))
        ()

    let of_pub_key = CCFun.id
  end

  type t =
    | HS256 of string
    | HS512 of string
    | RS256 of Pub_key.t

  let rs256_verify key hp signature =
    let cs = Cstruct.of_string signature in
    let hs = Cstruct.of_string hp in
    Mirage_crypto_pk.Rsa.PKCS1.verify ~hashp:(( = ) `SHA256) ~key ~signature:cs (`Message hs)

  let mac_verify algo hp signature = Cstruct.to_string (algo (Cstruct.of_string hp)) = signature

  let verify t hp signature =
    let f =
      match t with
      | HS256 x -> mac_verify (Mirage_crypto.Hash.SHA256.hmac ~key:(Cstruct.of_string x))
      | HS512 x -> mac_verify (Mirage_crypto.Hash.SHA512.hmac ~key:(Cstruct.of_string x))
      | RS256 x -> rs256_verify x
    in
    f hp signature

  let to_string = function
    | HS256 _ -> "HS256"
    | HS512 _ -> "HS512"
    | RS256 _ -> "RS256"
end

module Signer = struct
  module Priv_key = struct
    type t = Mirage_crypto_pk.Rsa.priv

    let of_priv_key = CCFun.id
  end

  type t =
    | HS256 of string
    | HS512 of string
    | RS256 of Priv_key.t

  let rs256_sign key hp =
    Cstruct.to_string
      (Mirage_crypto_pk.Rsa.PKCS1.sign ~hash:`SHA256 ~key (`Message (Cstruct.of_string hp)))

  let mac_sign algo hp = Cstruct.to_string (algo (Cstruct.of_string hp))

  let sign t hp =
    let f =
      match t with
      | HS256 x -> mac_sign (Mirage_crypto.Hash.SHA256.hmac ~key:(Cstruct.of_string x))
      | HS512 x -> mac_sign (Mirage_crypto.Hash.SHA512.hmac ~key:(Cstruct.of_string x))
      | RS256 x -> rs256_sign x
    in
    f hp

  let to_string = function
    | HS256 _ -> "HS256"
    | HS512 _ -> "HS512"
    | RS256 _ -> "RS256"
end

module Header = struct
  type t = (string * string) list

  let create ?(rest = []) ?(typ = "JWT") alg = ("typ", typ) :: ("alg", alg) :: rest
  let algorithm = CCList.Assoc.get_exn ~eq:String.equal "alg"
  let typ = CCList.Assoc.get_exn ~eq:String.equal "typ"
  let get = CCList.Assoc.get ~eq:String.equal

  let to_json t =
    `Assoc
      (CCList.sort
         (fun (c1, _) (c2, _) -> CCString.compare c1 c2)
         (CCList.map (fun (c, v) -> (c, `String v)) t))

  let to_string header =
    let json = to_json header in
    Yojson.Safe.to_string json

  let of_json =
    CCOption.wrap (fun json ->
        let assoc = Yojson.Safe.Util.to_assoc json in
        CCList.map
          (fun (c, v) ->
            match v with
            | `String s -> (c, s)
            | _ -> failwith "bad json")
          assoc)

  let of_string str =
    let open CCOption.Infix in
    CCOption.wrap Yojson.Safe.from_string str >>= fun json -> of_json json
end

module Claim = struct
  type t = string

  let iss = "iss"
  let sub = "sub"
  let aud = "aud"
  let exp = "exp"
  let nbf = "nbf"
  let iat = "iat"
  let jti = "jti"
  let ctyp = "ctyp"
  let auth_time = "auth_time"
  let nonce = "nonce"
  let acr = "acr"
  let amr = "amr"
  let azp = "azp"
end

module Payload = struct
  module Claim_map = CCMap.Make (CCString)

  type typs = Yojson.Safe.t
  type t = typs Claim_map.t

  let empty = Claim_map.empty
  let add_claim claim value t = Claim_map.add claim value t
  let find_claim claim t = Claim_map.get claim t

  let find_claim_string claim t =
    match find_claim claim t with
    | Some (`String v) -> Some v
    | _ -> None

  let find_claim_bool claim t =
    match find_claim claim t with
    | Some (`Bool v) -> Some v
    | _ -> None

  let find_claim_float claim t =
    match find_claim claim t with
    | Some (`Float v) -> Some v
    | _ -> None

  let find_claim_int claim t =
    match find_claim claim t with
    | Some (`Int v) -> Some v
    | _ -> None

  let of_json =
    CCOption.wrap (fun json ->
        CCListLabels.fold_left
          ~f:(fun acc (claim, v) -> add_claim claim v acc)
          ~init:empty
          (Yojson.Safe.Util.to_assoc json))

  let of_string str =
    let open CCOption.Infix in
    CCOption.wrap Yojson.Safe.from_string str >>= fun json -> of_json json

  let to_json t =
    let t = (t : t :> Yojson.Safe.t Claim_map.t) in
    `Assoc (CCList.sort (fun (c1, _) (c2, _) -> CCString.compare c1 c2) (Claim_map.to_list t))

  let to_string t = Yojson.Safe.to_string (to_json t)
end

type decoded = string
type verified = unit

type 'a t = {
  header : Header.t;
  payload : Payload.t;
  signature : string;
  hp : 'a;
}

let b64_url_encode str = Base64.encode_exn ~pad:false ~alphabet:Base64.uri_safe_alphabet str

let b64_url_decode str =
  CCOption.wrap (Base64.decode_exn ~pad:false ~alphabet:Base64.uri_safe_alphabet) str

let of_header_and_payload signer header payload =
  let b64_header = b64_url_encode (Header.to_string header) in
  let b64_payload = b64_url_encode (Payload.to_string payload) in
  let unsigned_token = b64_header ^ "." ^ b64_payload in
  let signature = Signer.sign signer unsigned_token in
  { header; payload; signature; hp = () }

let header t = t.header
let payload t = t.payload
let signature t = t.signature

let token t =
  let b64_header = b64_url_encode (Header.to_string (header t)) in
  let b64_payload = b64_url_encode (Payload.to_string (payload t)) in
  let b64_signature = b64_url_encode (signature t) in
  b64_header ^ "." ^ b64_payload ^ "." ^ b64_signature

let of_token token =
  let token_splitted = CCString.split_on_char '.' token in
  match token_splitted with
  | [ header_encoded; payload_encoded; signature_encoded ] ->
      let open CCOption.Infix in
      b64_url_decode header_encoded
      >>= fun header_decoded ->
      Header.of_string header_decoded
      >>= fun header ->
      b64_url_decode payload_encoded
      >>= fun payload_decoded ->
      Payload.of_string payload_decoded
      >>= fun payload ->
      b64_url_decode signature_encoded
      >>= fun signature ->
      Some { header; payload; signature; hp = header_encoded ^ "." ^ payload_encoded }
  | _ -> None

let verify verifier t =
  let alg = Header.algorithm t.header in
  if alg = Verifier.to_string verifier && Verifier.verify verifier t.hp t.signature then
    Some { header = t.header; payload = t.payload; signature = t.signature; hp = () }
  else None

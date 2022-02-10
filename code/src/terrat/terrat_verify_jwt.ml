module Sql = struct
  let read_sql fname = CCOpt.get_exn_or fname (Terrat_files_github.read fname)

  let select_installation_pub_key =
    Pgsql_io.Typed_sql.(
      sql // Ret.varchar /^ read_sql "select_installation_pub_key.sql" /% Var.bigint "id")
end

type t = Jwt.verified Jwt.t * int * int * int64

type err =
  [ `Expired
  | `Decode_error
  | `Verify_error
  | Pgsql_pool.err
  | Pgsql_io.err
  ]
[@@deriving show]

let decode_jwt headers =
  let open CCOpt.Infix in
  (* Not using get_authorization because it doesn't do anything useful for Bearer tokens *)
  Cohttp.Header.get headers "authorization"
  >>= fun auth ->
  CCString.Split.left ~by:" " auth
  >>= function
  | bearer, token when CCString.(equal (lowercase_ascii bearer) "bearer") ->
      Jwt.of_token token
      >>= fun jwt ->
      let payload = Jwt.payload jwt in
      Jwt.Payload.find_claim_int Jwt.Claim.iat payload
      >>= fun iat ->
      Jwt.Payload.find_claim_int Jwt.Claim.exp payload
      >>= fun exp ->
      Jwt.Payload.find_claim_string Jwt.Claim.iss payload
      >>= fun iss -> CCOpt.wrap Int64.of_string iss >>= fun iss -> Some (jwt, iat, exp, iss)
  | _ -> None

let verify_jwt storage jwt installation_id =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch db Sql.select_installation_pub_key ~f:CCFun.id installation_id)
  >>= function
  | [ pub_key_pem ] -> (
      match X509.Public_key.decode_pem (Cstruct.of_string pub_key_pem) with
      | Ok (`RSA pub_key) ->
          let verifier = Jwt.Verifier.(RS256 (Pub_key.of_pub_key pub_key)) in
          Abb.Future.return (Ok (Jwt.verify verifier jwt))
      | _ -> assert false)
  | _ -> (* There can be only one matching id *) assert false

let verify storage headers =
  let open Abb.Future.Infix_monad in
  match decode_jwt headers with
  | Some (jwt, iat, exp, iss) ->
      Abb.Sys.time ()
      >>= fun now ->
      if float iat <= now && now <= float exp then
        verify_jwt storage jwt iss
        >>= function
        | Ok (Some verified) -> Abb.Future.return (Ok (verified, iat, exp, iss))
        | Ok _ -> Abb.Future.return (Error `Verify_error)
        | Error (#Pgsql_pool.err | #Pgsql_io.err) as err -> Abb.Future.return err
      else Abb.Future.return (Error `Expired)
  | None -> Abb.Future.return (Error `Decode_error)

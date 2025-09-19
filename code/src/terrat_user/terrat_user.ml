module Sql = struct
  let select_system_user () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ "select id from users2 where type = 'system'")
end

module Capability = struct
  module Cs = Terrat_access_token_caps
  module E = Cs.Event

  type t =
    | Access_token_create
    | Access_token_refresh
    | Installation_id of string
    | Kv_store_read
    | Kv_store_write
    | Vcs of string
  [@@deriving show, eq, ord]

  let mask ~mask t =
    let module Set = CCSet.Make (struct
      type nonrec t = t

      let compare = compare
    end) in
    let mask = Set.of_list mask in
    let t = Set.of_list t in
    Set.to_list @@ Set.inter mask t

  let to_yojson' = function
    | Access_token_create -> E.Access_token_create "access_token_create"
    | Access_token_refresh -> E.Access_token_refresh "access_token_refresh"
    | Installation_id id -> E.Installation_id { Cs.Installation_id.name = "installation_id"; id }
    | Kv_store_read -> E.Kv_store_read "kv_store_read"
    | Kv_store_write -> E.Kv_store_write "kv_store_write"
    | Vcs vcs -> E.Vcs { Cs.Vcs.name = "vcs"; vcs }

  let to_yojson = CCFun.(to_yojson' %> E.to_yojson)

  let of_yojson json =
    let open CCResult.Infix in
    E.of_yojson json
    >>= function
    | E.Access_token_create _ -> Ok Access_token_create
    | E.Access_token_refresh _ -> Ok Access_token_refresh
    | E.Installation_id { Cs.Installation_id.name = _; id } -> Ok (Installation_id id)
    | E.Kv_store_read _ -> Ok Kv_store_read
    | E.Kv_store_write _ -> Ok Kv_store_write
    | E.Vcs { Cs.Vcs.name = _; vcs } -> Ok (Vcs vcs)
end

type create_system_user_err = Pgsql_io.err [@@deriving show]

type t = {
  access_token_id : Uuidm.t option;
  capabilities : Capability.t list;
  id : Uuidm.t;
}
[@@deriving show, eq]

let make ?access_token_id ?(capabilities = []) ~id () = { access_token_id; capabilities; id }

let create_system_user ?access_token_id ?capabilities db =
  let open Abbs_future_combinators.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.select_system_user ()) ~f:CCFun.id
  >>= function
  | [] -> assert false
  | id :: _ -> Abb.Future.return (Ok (make ?access_token_id ?capabilities ~id ()))

let access_token_id t = t.access_token_id
let id t = t.id
let capabilities t = t.capabilities
let has_capability cap t = CCList.mem ~eq:Capability.equal cap t.capabilities

let rem_capability cap t =
  { t with capabilities = CCList.remove ~eq:Capability.equal ~key:cap t.capabilities }

module Token = struct
  module Sql = struct
    let select_encryption_key () =
      (* The hex conversion is so that there are no issues with escaping
         the string *)
      Pgsql_io.Typed_sql.(
        sql
        //
        (* data *)
        Ret.ud' CCFun.(Cstruct.of_hex %> CCOption.return)
        /^ "select encode(data, 'hex') from encryption_keys order by rank")
  end

  (* The internal representation in JWT.  Prefix everything with "tt" to avoid
     conflict with any existing JWT claims *)
  module Repr = struct
    type t = {
      access_token_id : string option; [@default None]
      capabilities : Capability.t list;
      user_id : string;
    }
    [@@deriving yojson { strict = false }]
  end

  type of_token_err' =
    [ `Decode_err
    | `Data_decode_err of string
    | `Expired_token_err of (t[@opaque])
    ]
  [@@deriving show]

  type of_token_err =
    [ of_token_err'
    | Pgsql_io.err
    ]
  [@@deriving show]

  type to_token_err' = [ `Expiration_too_long_err of string ] [@@deriving show]

  type to_token_err =
    [ to_token_err'
    | Pgsql_io.err
    ]
  [@@deriving show]

  let rec try_all_keys decoded_jwt = function
    | [] -> None
    | k :: ks -> (
        let verifier = Jwt.Verifier.HS256 k in
        match Jwt.verify verifier decoded_jwt with
        | Some t -> Some t
        | None -> try_all_keys decoded_jwt ks)

  let of_token' ~now ~keys token =
    let mk expired t = if expired then Error (`Expired_token_err t) else Ok t in
    match Jwt.of_token token with
    | Some decoded_jwt -> (
        let expired =
          CCOption.map_or ~default:false (fun exp -> CCFloat.of_int exp < now)
          @@ Jwt.Payload.find_claim_int Jwt.Claim.exp
          @@ Jwt.payload decoded_jwt
        in
        match try_all_keys decoded_jwt keys with
        | Some jwt -> (
            match Jwt.Payload.find_claim "terrateam" @@ Jwt.payload jwt with
            | Some repr -> (
                match Repr.of_yojson repr with
                | Ok { Repr.access_token_id; user_id; capabilities } -> (
                    match
                      (Uuidm.of_string user_id, CCOption.map Uuidm.of_string access_token_id)
                    with
                    | Some id, ((None as access_token_id) | Some (Some _ as access_token_id)) ->
                        mk expired { access_token_id; id; capabilities }
                    | None, _ -> Error (`Data_decode_err ("user_id: " ^ user_id))
                    | _, Some None ->
                        Error
                          (`Data_decode_err
                             ("access_token_id:" ^ CCOption.get_or ~default:"" access_token_id)))
                | Error err -> Error (`Data_decode_err err))
            | None -> Error `Decode_err)
        | None -> Error `Decode_err)
    | None -> Error `Decode_err

  let of_token db token =
    let open Abb.Future.Infix_monad in
    Abb.Sys.time ()
    >>= fun now ->
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id
    >>= fun keys ->
    Abb.Future.return @@ of_token' ~now ~keys:(CCList.map Cstruct.to_string keys) token

  let to_token' ?expiration ~now ~key { access_token_id; id; capabilities } =
    let mk =
      (* If there is an [access_token_id], then expiration is optional and can
         be any value.  However if NO [access_token_id] is present, then
         [expiration] must be present and it must be less than or equal to 1 minute. *)
      if
        access_token_id = None
        && CCOption.map_or ~default:true (fun exp -> Duration.to_min exp > 1) expiration
      then fun t -> Error (`Expiration_too_long_err t)
      else fun t -> Ok t
    in
    let repr =
      {
        Repr.access_token_id = CCOption.map Uuidm.to_string access_token_id;
        user_id = Uuidm.to_string id;
        capabilities;
      }
    in
    let payload =
      Jwt.Payload.empty
      |> Jwt.Payload.add_claim "terrateam" (Repr.to_yojson repr)
      |> fun p ->
      CCOption.map_or
        ~default:p
        (fun exp ->
          Jwt.Payload.add_claim Jwt.Claim.exp (`Int (CCFloat.to_int (now +. Duration.to_f exp))) p)
        expiration
    in
    let signer = Jwt.Signer.HS256 key in
    let header = Jwt.Header.create (Jwt.Signer.to_string signer) in
    let jwt = Jwt.of_header_and_payload signer header payload in
    mk (Jwt.token jwt)

  let to_token ?expiration db user =
    let open Abbs_future_combinators.Infix_result_monad in
    Pgsql_io.Prepared_stmt.fetch db (Sql.select_encryption_key ()) ~f:CCFun.id
    >>= function
    | [] -> assert false
    | key :: _ ->
        let open Abb.Future.Infix_monad in
        Abb.Sys.time ()
        >>= fun now ->
        Abb.Future.return @@ to_token' ?expiration ~now ~key:(Cstruct.to_string key) user
end

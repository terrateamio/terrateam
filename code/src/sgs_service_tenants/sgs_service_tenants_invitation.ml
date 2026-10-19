(* The token is 256 bits of CSPRNG output, not a signed payload.

   The magic-claim HMAC (sgs_service_license_ee_ep_magic_claim.ml) is deliberately not reused: an
   invitation must be single-use, revocable, re-validated at accept time, and listable in a UI, all
   of which need a row anyway.  Once the row exists the token has no reason to carry data, and pure
   entropy avoids every signed-token failure mode.  256 bits also takes brute force out of the
   threat model, which is why accept attempts are not rate limited.

   Only the SHA-256 is persisted, so a database dump yields no working links.  The prefix is part of
   the hash input, so renaming it is a hard break rather than a silent one, and it makes the secret
   greppable for secret scanners. *)
let token_prefix = "sgi_"

let mint_token () =
  token_prefix
  ^ Base64.encode_string
      ~alphabet:Base64.uri_safe_alphabet
      ~pad:false
      (Mirage_crypto_rng.generate 32)

let hash_token token = Digestif.SHA256.(to_raw_string (digest_string token))

module Role = struct
  type t =
    | Member
    | Admin

  let to_string = function
    | Member -> "member"
    | Admin -> "admin"

  let of_string = function
    | "member" -> Some Member
    | "admin" -> Some Admin
    | _ -> None
end

module State = struct
  type t =
    | Pending
    | Accepted
    | Revoked
    | Expired

  let to_string = function
    | Pending -> "pending"
    | Accepted -> "accepted"
    | Revoked -> "revoked"
    | Expired -> "expired"

  let of_string = function
    | "pending" -> Some Pending
    | "accepted" -> Some Accepted
    | "revoked" -> Some Revoked
    | "expired" -> Some Expired
    | _ -> None
end

type err = Pgsql_io.err [@@deriving show]

type create_err =
  [ `Already_pending
  | Pgsql_io.err
  ]
[@@deriving show]

type consume_err =
  [ `Not_found
  | `Expired
  | `Revoked
  | `Already_accepted
  | Pgsql_io.err
  ]
[@@deriving show]

type act_err =
  [ `Not_found
  | `Not_pending
  | `Cooldown
  | `Send_limit
  | Pgsql_io.err
  ]
[@@deriving show]

(* An invitation as the tenant's administrators see it.  [expired] is computed from [expires_at]
   rather than read from [state]: a timed-out row keeps [state = 'pending'] until its slot is needed,
   so the stored state alone would misreport it. *)
type t = {
  id : Uuidm.t;
  email : string;
  role : Role.t;
  state : State.t;
  created_at : string;
  expires_at : string;
  expired : bool;
  delivered : bool option;
  send_count : int;
  invited_by_name : string;
}

(* What [create] hands back.  The token appears here and nowhere else: only its hash is stored, so
   this is the single opportunity to show the caller a working link. *)
type created = {
  created_id : Uuidm.t;
  created_token : string;
  created_at : string;
  created_expires_at : string;
}

(* What [rotate] hands back.  Like [created], the token appears once and is not recoverable after. *)
type rotated = {
  rotated_token : string;
  rotated_created_at : string;
  rotated_expires_at : string;
  rotated_email : string;
  rotated_role : Role.t;
  rotated_tenant_name : string;
}

(* What [consume] hands back so the caller can complete the join in the same transaction. *)
type accepted = {
  accepted_id : Uuidm.t;
  accepted_tenant_id : Uuidm.t;
  accepted_email : string;
  accepted_role : Role.t;
}

(* What the unauthenticated preview needs, before any masking. *)
type preview = {
  preview_tenant_id : Uuidm.t;
  preview_tenant_name : string;
  preview_email : string;
  preview_role : Role.t;
  preview_state : State.t;
  preview_expires_at : string;
  preview_expired : bool;
  preview_inviter_name : string;
}

module Sql = struct
  let insert_invitation_sql = Mql_sql.read [%blob "./sql/insert_tenant_invitation.sql"]

  let insert_invitation () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      //
      (* created_at *)
      Ret.text
      //
      (* expires_at *)
      Ret.text
      /^ insert_invitation_sql
      /% Var.text "email"
      /% Var.smallint "ttl_hours"
      /% Var.uuid "invited_by"
      /% Var.text "role"
      /% Var.uuid "tenant_id"
      /% Var.bytea "token_hash")

  let expire_stale_sql = Mql_sql.read [%blob "./sql/expire_stale_tenant_invitations.sql"]

  let expire_stale () =
    Pgsql_io.Typed_sql.(sql /^ expire_stale_sql /% Var.uuid "tenant_id" /% Var.text "email")

  let consume_sql = Mql_sql.read [%blob "./sql/consume_tenant_invitation.sql"]

  let consume () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      //
      (* tenant_id *)
      Ret.uuid
      //
      (* email *)
      Ret.text
      //
      (* role *)
      Ret.text
      /^ consume_sql
      /% Var.uuid "user_id"
      /% Var.bytea "token_hash")

  let select_by_token_sql = Mql_sql.read [%blob "./sql/select_tenant_invitation_by_token.sql"]

  let select_by_token () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      //
      (* tenant_id *)
      Ret.uuid
      //
      (* tenant name *)
      Ret.text
      //
      (* email *)
      Ret.text
      //
      (* role *)
      Ret.text
      //
      (* state *)
      Ret.text
      //
      (* expires_at *)
      Ret.text
      //
      (* expired *)
      Ret.boolean
      //
      (* inviter name *)
      Ret.text
      /^ select_by_token_sql
      /% Var.bytea "token_hash")

  let select_by_tenant_sql = Mql_sql.read [%blob "./sql/select_tenant_invitations.sql"]

  let select_by_tenant () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      //
      (* email *)
      Ret.text
      //
      (* role *)
      Ret.text
      //
      (* state *)
      Ret.text
      //
      (* created_at *)
      Ret.text
      //
      (* expires_at *)
      Ret.text
      //
      (* expired *)
      Ret.boolean
      //
      (* delivered *)
      Ret.(option boolean)
      //
      (* send_count *)
      Ret.smallint
      //
      (* inviter name *)
      Ret.text
      //
      (* total_count *)
      Ret.bigint
      /^ select_by_tenant_sql
      /% Var.uuid "tenant_id"
      /% Var.(option (text "cursor"))
      /% Var.(option (uuid "cursor_id"))
      /% Var.smallint "limit")

  let select_for_update_sql = Mql_sql.read [%blob "./sql/select_tenant_invitation_for_update.sql"]

  let select_for_update () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      //
      (* email *)
      Ret.text
      //
      (* role *)
      Ret.text
      //
      (* state *)
      Ret.text
      //
      (* send_count *)
      Ret.smallint
      //
      (* in cooldown *)
      Ret.boolean
      //
      (* tenant name *)
      Ret.text
      /^ select_for_update_sql
      /% Var.uuid "id"
      /% Var.uuid "tenant_id")

  let revoke_sql = Mql_sql.read [%blob "./sql/revoke_tenant_invitation.sql"]

  let revoke () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      /^ revoke_sql
      /% Var.uuid "user_id"
      /% Var.uuid "id"
      /% Var.uuid "tenant_id")

  let rotate_sql = Mql_sql.read [%blob "./sql/rotate_tenant_invitation.sql"]

  let rotate () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* id *)
      Ret.uuid
      //
      (* created_at *)
      Ret.text
      //
      (* expires_at *)
      Ret.text
      /^ rotate_sql
      /% Var.bytea "token_hash"
      /% Var.smallint "ttl_hours"
      /% Var.uuid "id"
      /% Var.uuid "tenant_id")

  let record_send_sql = Mql_sql.read [%blob "./sql/record_tenant_invitation_send.sql"]

  let record_send () =
    Pgsql_io.Typed_sql.(
      sql /^ record_send_sql /% Var.(option (boolean "delivered")) /% Var.uuid "id")

  let count_by_inviter_sql = Mql_sql.read [%blob "./sql/count_tenant_invitations_by_inviter.sql"]

  let count_by_inviter () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* count *)
      Ret.bigint
      /^ count_by_inviter_sql
      /% Var.uuid "invited_by"
      /% Var.smallint "hours")

  let count_pending_sql = Mql_sql.read [%blob "./sql/count_pending_tenant_invitations.sql"]

  let count_pending () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* count *)
      Ret.bigint
      /^ count_pending_sql
      /% Var.uuid "tenant_id")
end

(* Annotated because [created] below repeats [created_at], so an unannotated accessor would bind to
   whichever record was defined last. *)
let id (t : t) = t.id
let email (t : t) = t.email
let role (t : t) = t.role
let state (t : t) = t.state
let expired (t : t) = t.expired
let send_count (t : t) = t.send_count
let created_at (t : t) = t.created_at
let expires_at (t : t) = t.expires_at
let delivered (t : t) = t.delivered
let invited_by_name (t : t) = t.invited_by_name

let create ~ttl_hours ~email ~role ~invited_by ~tenant_id db =
  let open Abbs_fc.Infix_result_monad in
  let token = mint_token () in
  (* Free the one-live-invitation-per-address slot if a previous invitation timed out, otherwise the
     partial unique index would make that address permanently un-invitable. *)
  Pgsql_io.Prepared_stmt.execute db (Sql.expire_stale ()) tenant_id email
  >>= fun () ->
  let open Abb.Future.Infix_monad in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.insert_invitation ())
    ~f:(fun id created_at expires_at -> (id, created_at, expires_at))
    email
    ttl_hours
    invited_by
    (Role.to_string role)
    tenant_id
    (hash_token token)
  >>= function
  | Ok ((id, created_at, expires_at) :: _) ->
      Abb.Future.return
        (Ok { created_id = id; created_token = token; created_at; created_expires_at = expires_at })
  | Ok [] -> assert false
  (* tenant_invitations_tenant_email_pending_idx: a live invitation for this address already exists.
     The stale ones were just expired, so this is genuinely current -- the caller turns it into a
     resend rather than a second live link. *)
  | Error (`Unique_violation_err _) -> Abbs_fc.return_err `Already_pending
  | Error (#Pgsql_io.err as err) -> Abbs_fc.return_err err

let consume ~token ~user_id db =
  let open Abbs_fc.Infix_result_monad in
  let token_hash = hash_token token in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.consume ())
    ~f:(fun accepted_id accepted_tenant_id accepted_email role ->
      {
        accepted_id;
        accepted_tenant_id;
        accepted_email;
        accepted_role = CCOption.get_or ~default:Role.Member (Role.of_string role);
      })
    user_id
    token_hash
  >>= function
  | accepted :: _ -> Abbs_fc.return_ok accepted
  (* Nothing matched, so read the row to say why.  Purely for the error message -- the decision has
     already been made by the update above, so this cannot reopen the race. *)
  | [] -> (
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_by_token ())
        ~f:(fun _ _ _ _ _ state _ expired _ -> (state, expired))
        token_hash
      >>? function
      | [] -> Error `Not_found
      | (state, expired) :: _ -> (
          match State.of_string state with
          | Some State.Revoked -> Error `Revoked
          | Some State.Accepted -> Error `Already_accepted
          | Some State.Expired -> Error `Expired
          | Some State.Pending when expired -> Error `Expired
          | Some State.Pending | None -> Error `Not_found))

let preview ~token db =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.select_by_token ())
    ~f:(fun
        _id
        preview_tenant_id
        preview_tenant_name
        preview_email
        role
        state
        preview_expires_at
        preview_expired
        preview_inviter_name
      ->
      {
        preview_tenant_id;
        preview_tenant_name;
        preview_email;
        preview_role = CCOption.get_or ~default:Role.Member (Role.of_string role);
        preview_state = CCOption.get_or ~default:State.Pending (State.of_string state);
        preview_expires_at;
        preview_expired;
        preview_inviter_name;
      })
    (hash_token token)
  >>| fun rows -> CCList.head_opt rows

let list ?cursor ~limit ~tenant_id db =
  let open Abbs_fc.Infix_result_monad in
  (* The cursor is the (created_at, id) of the last row of the previous page -- the full sort key, so
     invitations created in the same instant are split cleanly across a page boundary. *)
  let cursor_created_at, cursor_id =
    match cursor with
    | Some (created_at, id) -> (Some created_at, Some id)
    | None -> (None, None)
  in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.select_by_tenant ())
    ~f:(fun
        id
        email
        role
        state
        created_at
        expires_at
        expired
        delivered
        send_count
        invited_by_name
        total_count
      ->
      ( {
          id;
          email;
          role = CCOption.get_or ~default:Role.Member (Role.of_string role);
          state = CCOption.get_or ~default:State.Pending (State.of_string state);
          created_at;
          expires_at;
          expired;
          delivered;
          send_count;
          invited_by_name;
        },
        total_count ))
    tenant_id
    cursor_created_at
    cursor_id
    limit
  >>| fun rows ->
  (* The windowed total repeats on every row; an empty page means no invitations remain to show. *)
  let total = CCOption.map_or ~default:0 (fun (_, n) -> Int64.to_int n) (CCList.head_opt rows) in
  (CCList.map fst rows, total)

let revoke ~id ~tenant_id ~user_id db =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.revoke ()) ~f:CCFun.id user_id id tenant_id
  >>? function
  | _ :: _ -> Ok ()
  | [] -> Error `Not_found

(* Locked read shared by resend and re-issue, so both see the same cooldown and budget. *)
let lock ~id ~tenant_id db =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.select_for_update ())
    ~f:(fun _id email role state send_count in_cooldown tenant_name ->
      (email, role, state, send_count, in_cooldown, tenant_name))
    id
    tenant_id
  >>? function
  | [] -> Error `Not_found
  | row :: _ -> Ok row

let max_sends = 5

(* Re-issue a pending invitation: a fresh token, a reset lifetime, one more send against the budget.

   There is no "resend the same link" variant, because there cannot be one -- only the token's hash is
   stored, so the original link is unrecoverable the moment it leaves [create].  Presenting resend and
   rotate as two operations would be two names for this one, and would imply a guarantee (the old link
   keeps working) that the storage model cannot honour.  The caller must tell the recipient the
   previous link is dead.

   The cooldown and the send budget live here rather than in the endpoint so they cannot be bypassed by
   a second caller of [rotate]. *)
let rotate ~ttl_hours ~authorize_role ~id ~tenant_id db =
  let open Abbs_fc.Infix_result_monad in
  lock ~id ~tenant_id db
  >>= fun (email, role, state, send_count, in_cooldown, tenant_name) ->
  (* TODO: don't default here, fail on bad 'role' value *)
  let role = CCOption.get_or ~default:Role.Member (Role.of_string role) in
  (* Asked the moment the row is read, before cooldown, send budget or state are consulted: whether
     the caller may hand out this invitation's role is not a reason to refuse *this* reissue but a
     question of authority, and answering it after a business rule would let an unauthorized caller
     read the row's state off the error they get back. *)
  match (authorize_role role, State.of_string state) with
  | false, _ -> Abbs_fc.return_err `Not_authorized
  | true, Some State.Pending when in_cooldown -> Abbs_fc.return_err `Cooldown
  | true, Some State.Pending when send_count >= max_sends -> Abbs_fc.return_err `Send_limit
  | true, Some State.Pending -> (
      let token = mint_token () in
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.rotate ())
        ~f:(fun _id created_at expires_at -> (created_at, expires_at))
        (hash_token token)
        ttl_hours
        id
        tenant_id
      >>? function
      | (created_at, expires_at) :: _ ->
          Ok
            {
              rotated_token = token;
              rotated_created_at = created_at;
              rotated_expires_at = expires_at;
              rotated_email = email;
              rotated_role = role;
              rotated_tenant_name = tenant_name;
            }
      | [] -> Error `Not_pending)
  | true, Some (State.Accepted | State.Revoked | State.Expired) | true, None ->
      Abbs_fc.return_err `Not_pending

let record_send ~delivered ~id db =
  Pgsql_io.Prepared_stmt.execute db (Sql.record_send ()) delivered id

let count_by_inviter ~hours ~invited_by db =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.count_by_inviter ()) ~f:CCFun.id invited_by hours
  >>= function
  | count :: _ -> Abbs_fc.return_ok (Int64.to_int count)
  | [] -> assert false

let count_pending ~tenant_id db =
  let open Abbs_fc.Infix_result_monad in
  Pgsql_io.Prepared_stmt.fetch db (Sql.count_pending ()) ~f:CCFun.id tenant_id
  >>= function
  | count :: _ -> Abbs_fc.return_ok (Int64.to_int count)
  | [] -> assert false

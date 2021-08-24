type t = Jwt.verified Jwt.t * int * int * int64

type err =
  [ `Expired
  | `Decode_error
  | `Verify_error
  | Pgsql_pool.err
  | Pgsql_io.err
  ]

val pp_err : Format.formatter -> err -> unit

val show_err : err -> string

(** Takes a JWT from headers and verifies that it is validly signed with the
   [installation_id] that corresponds with the [iss] in the JWT. *)
val verify : Terrat_storage.t -> Cohttp.Header.t -> (t, [> err ]) result Abb.Future.t

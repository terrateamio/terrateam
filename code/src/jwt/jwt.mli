(** Implement parsing and verifying JSON Web Tokens (JWTs). A JWT starts out as
   a string, then is decoded, and from there it can be verified against the
   correct verifier, at which point it becomes verified. *)

(** Used to verify the signature of a JWT. *)
module Verifier : sig
  module Pub_key : sig
    type t

    (** [e] and [n] are encoded as they would show up in a JWK. *)
    val create : e:string -> n:string -> t option
  end

  type t =
    | HS256 of string
    | HS512 of string
    | RS256 of Pub_key.t

  val to_string : t -> string
end

module Header : sig
  type t

  val create : ?rest:(string * string) list -> ?typ:string -> string ->  t

  val algorithm : t -> string

  val typ : t -> string

  val get : string -> t -> string option

  val to_string : t -> string

  val to_json : t -> Yojson.Basic.t

  val of_string : string -> t option

  val of_json : Yojson.Basic.t -> t option
end

module Claim : sig
  type t = string

  val iss : t
  val sub : t
  val aud : t
  val exp : t
  val nbf : t
  val iat : t
  val jti : t
  val ctyp : t
  val auth_time : t
  val nonce : t
  val acr : t
  val amr : t
  val azp : t
end

module Payload : sig
  type typs = [ `Bool of bool | `Float of float | `Int of int | `String of string ]
  type t

  val empty : t

  val add_claim : Claim.t -> typs -> t -> t

  val find_claim : Claim.t -> t -> typs option

  val find_claim_string : Claim.t -> t -> string option
  val find_claim_bool : Claim.t -> t -> bool option
  val find_claim_float : Claim.t -> t -> float option
  val find_claim_int : Claim.t -> t -> int option

  val of_json : Yojson.Basic.t -> t option

  val to_json : t -> Yojson.Basic.t

  val to_string : t -> string

  val of_string : string -> t option
end

(** A decoded JWT has just been successfully parsed. *)
type decoded

(** A verified JWT means that the signature has been verified against the
   content. *)
type verified

type 'a t

(* Not implemented yet *)
(* val of_header_and_payload : Verifier.t -> Header.t -> Payload.t -> verified t option *)

val header : 'a t -> Header.t

val payload : 'a t -> Payload.t

val signature : verified t -> string

(* Not implemented yet *)
(* val token : verified t -> string *)

val of_token : string -> decoded t option

(** Verify a decoded JWT against a particular verifier.  The alg in the JWT must
   match that of the verifier.  This is verified against the un-parse JWT. *)
val verify : Verifier.t -> decoded t -> verified t option

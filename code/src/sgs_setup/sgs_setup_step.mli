(** The setup step a deployment still has to take, in the order the console drives them: a license
    first, then the first admin of an installation that authenticates locally. *)
type t =
  [ `License  (** No valid license: the license step comes first. *)
  | `Register
    (** Licensed, local authentication, no human user yet: the register step, which
        [POST /api/v1/setup/admin] performs. *)
  | `Done  (** Licensed, and a human user exists or OAuth creates the users. *)
  ]
[@@deriving show, eq]

(** [next ~requirement config db] is the step the deployment is at, [requirement] being what the
    edition requires before setup may proceed. OAuth sign-ups arrive through the identity provider
    and create their own user, so only licensing decides it there. *)
val next :
  requirement:Sgs_service_license.requirement ->
  Sgs_config.t ->
  Pgsql_io.t ->
  (t, [> Pgsql_io.err ]) result Abb.Future.t

type t [@@deriving show, eq]

val make : ?email:string -> ?name:string -> ?avatar_url:string -> id:Uuidm.t -> unit -> t
val avatar_url : t -> string option
val email : t -> string option
val id : t -> Uuidm.t
val name : t -> string option

val enforce_installation_access :
  Terrat_storage.t ->
  t ->
  int ->
  ('a, 'b) Brtl_ctx.t ->
  (unit, ('a, [> `Forbidden | `Internal_server_error ]) Brtl_ctx.t) result Abb.Future.t

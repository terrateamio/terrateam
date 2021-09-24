(** {1 Context}

   A context is represents the request as well as the response.  The type
   variables represent the type of the body as well as the response object.
   This is done so the context can meaningfully change over time and invariants
   can be enforced.  For example, the post-handlers requires that a body has
   been set and thus enforce that with the type.  Similarly, the pre-handlers
   run before the body has been read whereas the code which writes the response
   out expects a string body. *)
type ('a, 'b) t

module Request : Cohttp.S.Request with type t = Cohttp.Request.t

(** Create a context with a [unit] body and a [unit] response.  This convention
   means that they have not been set . *)
val create : string -> Request.t -> (unit, unit) t

(** {1 Metadata}

   A context has metadata associated with it that can be used by any component
   with the key.  The metadata is implemented as a hetergeneous map [Hmap] so it
   can store a value of any type given the same key.

   Note that the key is a value and must be the same key value used to insert
   it.  For example, the following [v1] and [v2] are different keys despite both
   referencing [int] values.

   {[let v1 : int Hmap.key = Hmap.Key.create() and v2 : int Hmap.key =
   Hmap.Key.create () in ...]} *)

(** Find a metadata value. *)
val md_find : 'k Hmap.key -> ('a, 'b) t -> 'k option

(** Add or update a metadata value.  If it already exists its value is updated
   if it does not exist it is created. *)
val md_add : 'k Hmap.key -> 'k -> ('a, 'b) t -> ('a, 'b) t

(** Remove a key from metadata.  The key does not have to exist. *)
val md_rem : 'k Hmap.key -> ('a, 'b) t -> ('a, 'b) t

(** {1 Getters and Setters} *)

(** Get the URI of the request.  If the scheme is not in the URI, check if there
   is an [x-forwarded-proto] header and use that otherwise set to [http] *)
val uri : ('a, 'b) t -> Uri.t

(** Get the body. *)
val body : ('a, 'b) t -> 'a

(** Set the body, the new context will have the type of new body. *)
val set_body : 'a -> ('c, 'b) t -> ('a, 'b) t

(** Get the response. *)
val response : ('a, 'b) t -> 'b

(** Set the response. *)
val set_response : 'b -> ('a, 'c) t -> ('a, 'b) t

(** Get the request value. *)
val request : ('a, 'b) t -> Request.t

(** Address of the remote machine *)
val remote_addr : ('a, 'b) t -> string

(** Context unique identifier.  Every context created gets a unique
   identifier. *)
val token : ('a, 'b) t -> string

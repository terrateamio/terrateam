module Method : sig
  type t =
    [ `GET
    | `PUT
    | `POST
    | `DELETE
    ]
end

module Response : sig
  type t = {
    status : int;
    text : string;
  }

  val text : t -> string

  val status : t -> int
end

(** Send a request to [url] with [body] using [meth].  A successful response
   means that the destination responded with a valid HTTP response, even if the
   HTTP response constitutes an error. *)
val send :
  ?body:string ->
  meth:Method.t ->
  url:string ->
  unit ->
  (Response.t, [> `Error ]) result Abb_fut_js.t

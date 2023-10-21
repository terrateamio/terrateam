module Method : sig
  type t =
    [ `GET
    | `PUT
    | `POST
    | `DELETE
    ]
end

module Response : sig
  type t

  val text : t -> string
  val status : t -> int
  val headers : t -> (string * string) list
end

(** Send a request to [url] with [body] using [meth].  A successful response
   means that the destination responded with a valid HTTP response, even if the
   HTTP response constitutes an error. *)
val fetch :
  ?headers:(string * string) list ->
  ?body:string ->
  meth:Method.t ->
  url:string ->
  unit ->
  (Response.t, [> `Js_err of Jv.Error.t ]) result Abb_fut_js.t

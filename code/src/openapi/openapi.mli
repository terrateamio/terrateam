type err = [ `Error of string ]

module Response : sig
  type 'a t [@@deriving show]

  val make : headers:(string * string) list -> status:int -> 'a -> 'a t
  val value : 'a t -> 'a
  val headers : 'a t -> (string * string) list
  val status : 'a t -> int
end

module Request : sig
  module Var : sig
    type _ v =
      | Array : 'a v -> 'a list v
      | Option : 'a v -> 'a option v
      | Int : int v
      | Int64 : int64 v
      | String : string v
      | Bool : bool v
      | Null : unit v

    type t = Var : ('a * 'a v) -> t
  end

  type 'a t

  val make :
    ?body:Yojson.Safe.t ->
    headers:(string * Var.t) list ->
    url_params:(string * Var.t) list ->
    query_params:(string * Var.t) list ->
    url:string ->
    responses:(string * (string -> ('a, string) result)) list ->
    [ `Get | `Post | `Delete | `Patch | `Put ] ->
    'a t

  val with_base_url : Uri.t -> 'a t -> 'a t
  val with_url : Uri.t -> 'a t -> 'a t
  val add_headers : (string * string) list -> 'a t -> 'a t
end

module type IO = sig
  type 'a t
  type err

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  (** Perform an HTTP calling returning a response with body, if present *)
  val call :
    ?body:string ->
    headers:(string * string) list ->
    meth:[ `Get | `Post | `Delete | `Patch | `Put ] ->
    Uri.t ->
    (string Response.t, [> `Io_err of err ]) result t
end

module Make (Io : IO) : sig
  val call :
    'a Request.t ->
    ( 'a Response.t,
      [> `Conversion_err of string * string Response.t
      | `Missing_response of string Response.t
      | `Io_err of Io.err
      ] )
    result
    Io.t
end

val of_json_body :
  ('a -> 'b) -> (Yojson.Safe.t -> ('a, string) result) -> string -> ('b, string) result

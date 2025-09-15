module Http : module type of Cohttp_abb.Make (Abb)
module Response : Cohttp.S.Response with type t = Cohttp.Response.t

module Encoding : sig
  type t

  val fixed : t
  val chunked : t
end

type t

val create :
  ?version:Cohttp.Code.version ->
  ?headers:Cohttp.Header.t ->
  ?encoding:Encoding.t ->
  status:Cohttp.Code.status_code ->
  string ->
  t

val create_stream :
  ?version:Cohttp.Code.version ->
  ?headers:Cohttp.Header.t ->
  ?encoding:Encoding.t ->
  status:Cohttp.Code.status_code ->
  (Http.Response_io.writer -> unit Abb.Future.t) ->
  t

val version : t -> Cohttp.Code.version
val status : t -> Cohttp.Code.status_code
val body : t -> Http.Response_io.writer -> unit Abb.Future.t
val headers : t -> Cohttp.Header.t
val add_header : string -> string -> t -> t
val add_header_if_not_exists : string -> string -> t -> t
val response : t -> Response.t

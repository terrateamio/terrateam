module Make(Abb : Abb_intf.S) : sig
  module Response : Cohttp.S.Response with type t = Cohttp.Response.t

  type t

  val create :
    ?version:Cohttp.Code.version ->
    ?headers:Cohttp.Header.t ->
    status:Cohttp.Code.status_code ->
    string ->
    t

  val version: t -> Cohttp.Code.version
  val status: t -> Cohttp.Code.status_code
  val body: t -> string

  val headers: t -> Cohttp.Header.t
  val add_header: string -> string -> t -> t

  val response: t -> Response.t
end

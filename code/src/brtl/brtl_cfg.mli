module Make(Abb : Abb_intf.S) : sig
  type t

  val create :
    port:int ->
    read_header_timeout:Duration.t option ->
    handler_timeout:Duration.t option ->
    t

  val port : t -> int
  val read_header_timeout : t -> Duration.t option
  val handler_timeout : t -> Duration.t option
end

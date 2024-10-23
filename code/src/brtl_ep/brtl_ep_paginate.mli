module type S = sig
  type cursor
  type query
  type t
  type err

  val next : ?cursor:cursor -> query -> (t, err) result Abb.Future.t
  val prev : ?cursor:cursor -> query -> (t, err) result Abb.Future.t
  val to_yojson : t -> Yojson.Safe.t
  val cursor_of_first : t -> string list option
  val cursor_of_last : t -> string list option

  (** Says if there is another page in whatever direction was chosen.  If [next]
      was called, it means there is another page after that page shown and if
      [prev] it means there is another page prior to that page. *)
  val has_another_page : t -> bool

  val rspnc_of_err : token:string -> err -> Brtl_rspnc.t
end

module Param : sig
  module Typ : sig
    type 'a t

    val ud : (string list -> 'a option) -> 'a t
    val ud' : (string -> 'a option) -> 'a t
    val string : string t
    val int : int t
    val tuple : 'a t * 'b t -> ('a * 'b) t
    val tuple3 : 'a t * 'b t * 'c t -> ('a * 'b * 'c) t
    val tuple4 : 'a t * 'b t * 'c t * 'd t -> ('a * 'b * 'c * 'd) t
  end

  type 'a t

  val of_param : 'a Typ.t -> string list -> 'a t option
end

module Make (M : S) : sig
  val run :
    ?page:M.cursor Param.t ->
    page_param:string ->
    M.query ->
    (string, 'a) Brtl_ctx.t ->
    (string, Brtl_rspnc.t) Brtl_ctx.t Abb.Future.t
end

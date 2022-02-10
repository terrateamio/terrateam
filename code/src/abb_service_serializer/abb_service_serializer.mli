(** Serializes any function execution. *)

module Make (Fut : Abb_intf.Future.S) : sig
  type msg
  type t = (Abb_channel.Make(Fut).writer, msg) Abb_channel.Make(Fut).t

  val create : unit -> t Fut.t
  val run : t -> f:(unit -> 'a Fut.t) -> 'a Abb_channel_intf.channel_ret Fut.t

  module Mutex : sig
    type serializer = t
    type 'a t

    val create : serializer -> 'a -> 'a t
    val run : 'a t -> f:('a -> 'b Fut.t) -> 'b Abb_channel_intf.channel_ret Fut.t
  end
end

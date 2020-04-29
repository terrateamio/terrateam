(** [Abb_channel_queue] is an implementation of {!Abb_channel} and it is
    parameterized over a futures implementation.  It is a
    multiple-producer-single-consumer channel. *)
module Make (Fut : Abb_intf.Future.S) : sig
  module T : sig
    type 'a t

    (** Create a queue implementation.  An optional [fast_count] parameter
        specifies how large the queue can be before backpressure kicks in.  If
        the length of the queue is less than [fast_count], the future returned
        by [send] will be determined.  If the length is greater than
        [fast_count], the future will be determined when it is taken off of the
        queue. *)
    val create : ?fast_count:int -> unit -> 'a t Fut.t

    val send : 'a t -> 'a -> unit Abb_channel_intf.channel_ret Fut.t

    val recv : 'a t -> 'a Abb_channel_intf.channel_ret Fut.t

    val close : 'a t -> unit Fut.t

    val close_with_abort : 'a t -> unit Fut.t

    val closed : 'a t -> unit Fut.t
  end

  type 'a reader = (Abb_channel.Make(Fut).reader, 'a) Abb_channel.Make(Fut).t

  type 'a writer = (Abb_channel.Make(Fut).writer, 'a) Abb_channel.Make(Fut).t

  val to_abb_channel : 'a T.t -> 'a reader * 'a writer
end

(** Abb_channel_intf defines the interface for a single-producer-single-consumer
    channel.  An implementation might support multiple producers or consumers
    but it is not guaranteed.  The module type is parameterized over a futures
    module.  All of the functions can wait either as a form of back pressure or
    until an item is placed in the channel if it is empty. There is no function
    in the interface for creating a channel as that can be highly dependent on
    how the channel is implemented. *)

(** A channel can be closed *)
type 'a channel_ret = [ `Ok of 'a | `Closed ]

module Make (Fut : Abb_intf.Future.S) = struct

  (** Module type in terms of the future implementation. *)
  module type S = sig

    (** The message type the channel takes. *)
    type msg

    (** The type of the channel. *)
    type t

    (** Send a message on the channel.  The future returned will be determined
        when the value has been taken off of the channel.  If the channel has
        been closed prior to the call to send it will return [`Closed]. *)
    val send : t -> msg -> unit channel_ret Fut.t

    (** Take a message off the channel, the future returned is determined with
        the value in the channel, or [`Closed] if the channel has been closed,
        even if the channel has been closed after [recv] was called.  [`Closed]
        will not be returned until the channel has been entirely consumed. *)
    val recv : t -> msg channel_ret Fut.t

    (** Close the channel for sending, this can be called multiple times and the
        repeated calls are a noop.  All calls to [send] will evaluate to
        [`Closed] however calls to [recv] will return any messages that still
        exist on the channel.  If there are no messages in the channel, after
        calling this function all calls to [recv] will also evaluate to `Closed.
        In other words, this allows messages to be put on the channel, and then
        closed, preventing more work being put on it, while still allowing the
        other side of the channel to consume messages and operate on them. *)
    val close : t -> unit Fut.t

    (** Close the channel and abort any waiting futures for push-back that exist
        in the queue.  If the channel is already closed, this must abort any
        waiting work.  After this call has been evaluated, both [send] and
        [recv] will evaluate to [`Closed]. *)
    val close_with_abort : t -> unit Fut.t

    (** Returns a future that is evaluated when the channel is closed. *)
    val closed : t -> unit Fut.t
  end
end

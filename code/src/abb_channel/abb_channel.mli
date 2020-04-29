(** {!Abb_channel_intf} defines the generic channel interface over a futures
    implementation, this turns a module implementing the interface and an
    instance of that module type into an existential implementation of the
    channel.  In this way, different implementations but with a matching message
    type will have the same type.  This also implements a phantom type over the
    reader and writer, allowing to partition readers and writers.  The [close]
    function can be called on either side, however.  This is also parameterized
    over a future library implementation. *)

module Make (Fut : Abb_intf.Future.S) : sig
  type reader

  type writer

  (** The channel type, where the first type variable is if it is a reader or
      writer. *)
  type ('a, 'msg) t

  (** Take a module implementing the [Abb_channel_intf] interface, as applied
      over a future implementation, and an instance of the type defined in the
      module and returns an instance of the reader and writer. *)
  val create :
    (module Abb_channel_intf.Make(Fut).S with type t = 't and type msg = 'msg) ->
    't ->
    (reader, 'msg) t * (writer, 'msg) t

  val send : (writer, 'msg) t -> 'msg -> unit Abb_channel_intf.channel_ret Fut.t

  (** It's safe to [abort] a recv but not [cancel] without losing messages. *)
  val recv : (reader, 'msg) t -> 'msg Abb_channel_intf.channel_ret Fut.t

  (** Corresponds to {!Abb_channel_intf.Make(Fut).close}. *)
  val close : (writer, 'msg) t -> unit Fut.t

  (** Corresponds to {!Abb_channel_intf.Make(Fut).close_with_abort}. *)
  val close_reader : (reader, 'msg) t -> unit Fut.t

  (** Corresponds to {!Abb_channel_intf.Make(Fut).closed *)
  val closed : (writer, 'msg) t -> unit Fut.t

  module Combinators : sig
    (** Allow the common pattern of looping over the incomming messages with a
        state.  This like folding over the channel.  If the function, [f],
        throws an exception future will be evaluated to [`Exn exn]. *)
    val fold : init:'a -> f:('a -> 'b -> 'a Fut.t) -> (reader, 'b) t -> 'a Fut.t

    (** Iterate over the channel and call a function with the messages *)
    val iter : f:('a -> unit Fut.t) -> (reader, 'a) t -> unit Fut.t

    (** Fold over the channel and when it is closed execute the close function
        and return its value. *)
    val fold_with_close :
      init:'a -> f:('a -> 'b -> 'a Fut.t) -> close:('a -> 'c Fut.t) -> (reader, 'b) t -> 'c Fut.t

    (** Send a message to a channel where the message contains the promise.  The
        function will then return the value of the promise when it is evaluated.
        This captures a common pattern of treating a message like a function
        call that has a return value.  The promise passed in is what the
        receiver side will set as the return value. *)
    val send_promise :
      (writer, 'a) t -> 'a -> 'b Fut.Promise.t -> 'b Abb_channel_intf.channel_ret Fut.t

    val to_result : 'a Abb_channel_intf.channel_ret Fut.t -> ('a, [> `Closed ]) result Fut.t
  end
end

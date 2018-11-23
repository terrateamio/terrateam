(** Run a function in a service in the same memory-space as the creator of the
    service. *)
module Make (Fut : Abb_intf.Future.S) : sig

  type 'a r = (Abb_channel.Make(Fut).reader, 'a) Abb_channel.Make(Fut).t
  type 'a w = (Abb_channel.Make(Fut).writer, 'a) Abb_channel.Make(Fut).t

  (** Takes a function which is called with the reader and writer and returns
      when the service is complete.  The channel is closed by the code calling
      the function on all conditions, including if the function throws an
      exception.  The writer is passed in to the function as well as the reader
      so the service code can spawn other services and have it write to its
      channel. *)
  val create : ('a w -> 'a r -> unit Fut.t) -> 'a w Fut.t
end

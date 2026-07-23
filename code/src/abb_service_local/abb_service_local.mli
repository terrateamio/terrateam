(** [Abb_service_local] is domain-safe. It provides an abstraction for running a service in the same
    memory space as its creator, communicating with it via message passing on a channel. The
    service's work is encapsulated in a task.

    The {!Make.Request}, {!Make.call}, and {!Make.respond} helpers implement the
    request/reply-over-{!Abb_intf.Chan} pattern documented in RFD 675's "Safe cross-task patterns"
    section. Use them rather than embedding a [Promise.t] in your own [Msg.t] type — sharing a
    promise across tasks races on the promise cell because Abb_fut has no atomic on the state and no
    lock on [State.t] in release builds.

    {2 Domain-safety responsibility of the user}

    The helpers are domain-safe by construction: every Abb_fut cell stays in its owning chain;
    cross-task communication happens entirely through {!Abb_intf.Chan} (which is built for it).

    {b The user is responsible for the domain-safety of the values they pass through.} Specifically:

    - The [f] function passed to {!Make.respond} is invoked on the {i service task's} domain. Its
      closure captures whatever was in scope at the call site; if any captured value is mutable
      state owned by a different task or domain, it is unsafe to read or write from inside [f].
    - The [req] payload passed to {!Make.call} (and to {!Make.Make_typed.call}) is sent across a
      channel and consumed by the server task. The payload itself must be safe to read from the
      server's domain — typically immutable values, plain records of immutable data, or atomics.
    - The [wrap] function passed to {!Make.call} runs on the caller's domain and only builds the
      wire-bound message; this one is safe by virtue of where it runs.

    In short: the helpers move {i values} across domains via [Chan]; if a value carries mutable
    state, it is your responsibility to ensure that state is safe to access from either side. *)

module Make (S : Abb_intf.S) : sig
  type 'a t = 'a S.Chan.t

  (** Takes a function which is called with the channel and returns when the service is complete.
      The channel is closed by [create] when the function returns (including via exception). The
      same channel handle is returned to the caller so other code can send into it.

      [?capacity] (default [100]) is the channel's bounded capacity.

      [?name] is an optional name passed through to the underlying task, for debugging.

      [?pinned] (default [true]) is passed through to the underlying task; see
      {!Abb_intf.S.Task.run}. *)
  val create :
    ?capacity:int -> ?name:string -> ?pinned:bool -> ('a t -> unit S.Future.t) -> 'a t S.Future.t

  (** {2 Request/reply helpers}

      The remaining surface implements the request-with-reply-Chan pattern from RFD 675. *)

  module Request : sig
    (** A typed request envelope. ['req] is the request payload; ['resp] is the response type. The
        envelope embeds a private capacity-1 reply [Chan] that carries the response back to the
        caller as a {!Abb_intf.Future.Set.t} (so [`Det], [`Aborted], and [`Exn] all propagate).

        The envelope is built by {!call} on the caller's side and consumed by the server task. Users
        of this module do not construct {!Request.t} values directly. *)
    type ('req, 'resp) t

    (** The request payload. Server-side handlers extract this to inspect what the caller asked for.
    *)
    val payload : ('req, 'resp) t -> 'req

    (** The reply channel for this request. Use this only when the server cannot conveniently call
        {!respond} — for example, when the result is produced asynchronously by a callback or
        delivered out-of-order from a queue. Send a single [`Det _ | `Aborted | `Exn (_, _)] wire
        value into this chan to settle the caller's future. If you {!respond} instead, this access
        is not needed. *)
    val reply_chan : ('req, 'resp) t -> 'resp Abb_intf.Future.Set.t S.Chan.t
  end

  (** [call chan wrap req] is the caller side of the request/reply pattern. It:

      - allocates a capacity-1 reply [Chan];
      - constructs a {!Request.t} from [req] and the reply chan, wraps it via [wrap] into the
        service's [Msg.t], and sends it over [chan];
      - awaits the reply, re-materializing the server's terminal state ([`Det], [`Aborted], or
        [`Exn]) on the {i caller's} chain;
      - if the caller's future is aborted while waiting, closes the reply chan — which is the
        caller→worker abort signal. The server's {!respond} (or manual {!Request.reply_chan} usage)
        will then observe [`Chan_closed] on send and drop the result.

      Returns [Error `Chan_closed] when the service channel is closed. If the worker terminated with
      [`Aborted] or [`Exn (_, _)], the returned future is itself in the corresponding state —
      binding on it propagates the abort or exception through the caller's chain just as if the work
      had run there.

      {b Domain-safety:} the [req] value is consumed on the service task's domain. Pass values that
      are safe to read from there — typically immutable data. *)
  val call :
    'msg t ->
    (('req, 'resp) Request.t -> 'msg) ->
    'req ->
    ('resp, [> `Chan_closed ]) result S.Future.t

  (** [respond req f] is the server side of the request/reply pattern. It runs [f ()],
      {!Abb_intf.S.Future.await}s it, and sends the captured terminal state back through [req]'s
      reply chan. If the caller has already closed the reply chan (because its own future was
      aborted), the send fails with [`Chan_closed]; the failure is swallowed silently and the
      worker's result is dropped.

      Use this when the server can produce a response by invoking a function. If the response is
      produced out-of-band — e.g. delivered by an asynchronous callback or pulled from a queue —
      reach into {!Request.reply_chan} directly and send the wire value yourself.

      {b Domain-safety:} [f] runs on the service task's domain. Captured state must be safe for that
      domain to access. *)
  val respond : ('req, 'resp) Request.t -> (unit -> 'resp S.Future.t) -> unit S.Future.t

  (** [notify chan msg] sends a fire-and-forget message to the service. Equivalent to
      {!S.Chan.send}. Useful for messages that do not need a reply (e.g. [Cancel], [Work_done],
      [Suspend]).

      {b Domain-safety:} [msg] is consumed on the service task's domain; see the module-level note
      about user-supplied values. *)
  val notify : 'msg t -> 'msg -> (unit, [> `Chan_closed ]) result S.Future.t

  (** {2 Typed-service functor}

      For services whose every request expects a reply, defining a request GADT and instantiating
      {!Make_typed} eliminates the [Msg.t] boilerplate: the functor synthesizes the message
      envelope, channel type, and a typed {!Make_typed.call}.

      For services with mixed request/notify traffic (e.g. an executor that takes [Enqueue] {i and}
      [Work_done]), use the {!call}/{!respond}/{!notify} helpers directly against your own [Msg.t].
  *)

  (** Signature for the request GADT consumed by {!Make_typed}. Each constructor's index parameter
      is the response type for that request. *)
  module type REQ = sig
    type 'resp t
  end

  module Make_typed (R : REQ) : sig
    (** The wire message: a request GADT value bundled with its reply chan, with the response type
        hidden existentially so heterogeneous requests fit on one channel. *)
    type msg = Msg : ('resp R.t, 'resp) Request.t -> msg

    type svc = msg t

    (** Send [req] to the service and wait for the response on the caller's chain, exactly like
        {!call}. The response type ['resp] is determined by the [R.t] index, so consumers get typed
        results without any GADT pattern-match noise.

        {b Domain-safety:} as for {!call}, the [req] value is consumed on the service task's domain.
    *)
    val call : svc -> 'resp R.t -> ('resp, [> `Chan_closed ]) result S.Future.t

    (** Start a server task; identical semantics to the top-level {!create}. *)
    val create :
      ?capacity:int -> ?name:string -> ?pinned:bool -> (svc -> unit S.Future.t) -> svc S.Future.t
  end
end

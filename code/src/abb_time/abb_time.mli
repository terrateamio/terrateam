(** A type-safe interface to wall-clock, monotonic time, and spans. *)

module Monad : sig
  module type S = sig
    type +'a t
  end
end

(** Getting the time depends on side-effects from the system, so getting time is
    needs to be wrapped in some kind of monad.  [Abb_time] does not directly
    depend on [Abb_intf.S] because that is far too big of a dependency when all
    that [Abb_time] cares about is that the value returned from [time] and
    [monotonic] is wrapped in some monadic value. *)
module Time_make (M : Monad.S) : sig
  module type S = sig
    (** Return the time, in seconds as a float, since an epoch. *)
    val time : unit -> float M.t

    (** Return the elapsed time, in seconds as a float, since an arbitrary stable
        point in the past.  This is not affected by wall-clock changes. *)
    val monotonic : unit -> float M.t
  end
end

(** Represents span between two times. *)
module Span : sig
  type t

  val of_sec : float -> t

  val to_sec : t -> float

  (** Compare two spans, however beware that the underlying representation might
      be a float which makes this an untrustworthy comparison. *)
  val compare : t -> t -> int
end

module Make (M : Monad.S) (Time : Time_make(M).S) : sig
  (** Wall-clock time. *)
  module Wall : sig
    type t

    (** Return a value representing the wall-clock time from an epoch.  There is
        no guarantee on the relative values between two calls to [now]. *)
    val now : unit -> t M.t

    (** Subtract two times and return a [Span.t].  The first value is subtracted
        from the second value.

        It is guaranteed that {[ add t1 (diff t1 t2) = t2 ]} *)
    val diff : t -> t -> Span.t

    (** Add a [Span.t] to a time.

        It is guaranteed that {[ add t1 (diff t1 t2) = t2 ]} *)
    val add : t -> Span.t -> t

    val to_sec : t -> float

    val of_sec : float -> t

    (** Compare two wall-clock times, however beware that the underlying
        representation might be a float which makes this an untrustworthy
        comparison. *)
    val compare : t -> t -> int
  end

  (** Monotonic time. *)
  module Mono : sig
    type t

    (** Return a value representing the time since an arbitrary, stable, point
        in the past.  This is not affected by changes in the system time.
        Successive calls to [now] are guaranteed to be greater than or equal to
        each other. *)
    val now : unit -> t M.t

    (** Subtract two times and return a [Span.t].  The first value is subtracted
        from the second value.

        It is guaranteed that {[ add m1 (diff m1 m2) = m2 ]} *)
    val diff : t -> t -> Span.t

    (** Add a [Span.t] to a monotonic value.

        It is guaranteed that {[ add m1 (diff m1 m2) = m2 ]} *)
    val add : t -> Span.t -> t

    val to_sec : t -> float

    val of_sec : float -> t

    (** Compare two monotonic times, however beware that the underlying
        representation might be a float which makes this an untrustworthy
        comparison. *)
    val compare : t -> t -> int
  end
end

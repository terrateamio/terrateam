(** [Abb_data_source] provides was to express a source of data and semantic
    around it.  A common example is how a source of data is cached, such as for
    a span of time, LRU, or memoized. *)

module type S = sig
  type k
  type args
  type v
  type err

  val fetch : args -> (v, err) result Abb.Future.t
  val equal_k : k -> k -> bool
end

module type SRC = sig
  type opts
  type t
  type k
  type args
  type v
  type err

  val create : opts -> t
  val fetch : t -> k -> args -> (v, err) result Abb.Future.t
end

module Passthrough : sig
  module Make (M : S) :
    SRC
      with type opts = unit
       and type k = M.k
       and type args = M.args
       and type v = M.v
       and type err = M.err
end

module Memo : sig
  type opts = {
    on_hit : unit -> unit;
    on_miss : unit -> unit;
  }

  module Make (M : S) :
    SRC
      with type opts = opts
       and type k = M.k
       and type args = M.args
       and type v = M.v
       and type err = M.err
end

module Lru : sig
  type opts = {
    on_hit : unit -> unit;
    on_miss : unit -> unit;
    size : int;
  }

  module Make (M : S) :
    SRC
      with type opts = opts
       and type k = M.k
       and type args = M.args
       and type v = M.v
       and type err = M.err
end

module Expiring : sig
  type opts = {
    on_hit : unit -> unit;
    on_miss : unit -> unit;
    duration : Duration.t;
    size : int;
  }

  module Make (M : S) :
    SRC
      with type opts = opts
       and type k = M.k
       and type args = M.args
       and type v = M.v
       and type err = M.err
end

module Make (Abb : Abb_intf.S) : sig
  module type S = sig
    type k
    type args
    type v
    type err

    val fetch : args -> (v, err) result Abb.Future.t
    val equal_k : k -> k -> bool

    (** Given a value, return how much capacity it consumes. Must return a number greater than or
        equal to 0. *)
    val weight : v -> int
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
      capacity : int;
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
      on_evict : unit -> unit;
      duration : Duration.t;
      capacity : int;
    }

    module Make (M : S) :
      SRC
        with type opts = opts
         and type k = M.k
         and type args = M.args
         and type v = M.v
         and type err = M.err
  end

  module Filesystem : sig
    type cache_err =
      [ Abb_io_file.Make(Abb).with_file_err
      | Abb_intf.Errors.write
      | Abb_intf.Errors.read
      ]
    [@@deriving show]

    type 'v opts = {
      on_hit : unit -> unit;
      on_miss : unit -> unit;
      on_evict : unit -> unit;
      path : string;
      to_string : 'v -> string;
      of_string : string -> 'v option;
    }

    module Make (M : S with type k = string) :
      SRC
        with type opts = M.v opts
         and type k = M.k
         and type args = M.args
         and type v = M.v
         and type err =
          [ `Fetch_err of M.err
          | `Cache_err of cache_err
          ]
  end
end

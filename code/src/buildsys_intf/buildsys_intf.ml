module type S = sig
  type 'a c

  module State : sig
    type ('k, 'v) t

    val set_k : ('k, 'v) t -> 'k -> 'v -> unit c
    val get_k : ('k, 'v) t -> 'k -> 'v c
  end

  module Task : sig
    type ('k, 'v) t = ('k -> 'v c) -> 'v c
  end

  module Tasks : sig
    type ('k, 'v) t = ('k, 'v) State.t -> 'k -> ('k, 'v) Task.t option
  end

  module Build : sig
    type ('k, 'v) t = ('k, 'v) Tasks.t -> 'k -> ('k, 'v) State.t -> ('k, 'v) State.t c
  end
end

module Monad = struct
  module type S = sig
    type +'a t
  end
end

module Time_make (M : Monad.S) = struct
  module type S = sig
    val time : unit -> float M.t
    val monotonic : unit -> float M.t
  end
end

module Span = struct
  type t = float

  let of_sec = CCFun.id
  let to_sec = CCFun.id
  let compare = CCFloat.compare
end

module Make (M : Monad.S) (Time : Time_make(M).S) = struct
  module Wall = struct
    type t = float

    let now = Time.time
    let diff t1 t2 = t2 -. t1
    let add t s = t +. s
    let to_sec = CCFun.id
    let of_sec = CCFun.id
    let compare = CCFloat.compare
  end

  module Mono = struct
    type t = float

    let now = Time.monotonic
    let diff t1 t2 = t2 -. t1
    let add t s = t +. s
    let to_sec = CCFun.id
    let of_sec = CCFun.id
    let compare = CCFloat.compare
  end
end

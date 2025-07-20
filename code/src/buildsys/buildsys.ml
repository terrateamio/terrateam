module type S = sig
  module Key_repr : sig
    type t

    val equal : t -> t -> bool
  end

  type 'v k

  val key_repr_of_key : 'a k -> Key_repr.t

  module C : sig
    type 'a t

    val return : 'a -> 'a t
    val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
    val protect : (unit -> 'a t) -> 'a t t
  end

  module Notify : sig
    type t

    val create : unit -> t
    val notify : t -> unit C.t
    val wait : t -> unit C.t
  end

  module State : sig
    type t

    val set_k : t -> 'v k -> 'v -> unit C.t
    val get_k : t -> 'v k -> 'v C.t
    val get_k_opt : t -> 'v k -> 'v option C.t
  end
end

module type T = sig
  type 'v k
  type 'a c
  type state

  module Fetcher : sig
    type t = { fetch : 'r. 'r k -> 'r c }
  end

  module Task : sig
    type 'v t = state -> Fetcher.t -> 'v c
  end

  module Tasks : sig
    type t = { get : 'v. state -> 'v k -> 'v Task.t option c }
  end

  module Rebuilder : sig
    type t = { run : 'v. state -> 'v k -> 'v -> bool c }
  end

  module St : sig
    type t

    val create : state -> t
    val get_state : t -> state
  end

  val build : Rebuilder.t -> Tasks.t -> 'v k -> St.t -> 'v c
end

module Make (M : S) :
  T with type 'a k = 'a M.k and type 'a c = 'a M.C.t and type state = M.State.t = struct
  type 'a k = 'a M.k
  type 'a c = 'a M.C.t
  type state = M.State.t

  module Fetcher = struct
    type t = { fetch : 'r. 'r M.k -> 'r M.C.t }
  end

  module Task = struct
    type 'v t = M.State.t -> Fetcher.t -> 'v M.C.t
  end

  module Tasks = struct
    type t = { get : 'v. M.State.t -> 'v M.k -> 'v Task.t option M.C.t }
  end

  module Rebuilder = struct
    type t = { run : 'v. M.State.t -> 'v M.k -> 'v -> bool M.C.t }
  end

  module St = struct
    type t = {
      state : M.State.t;
      mutable running : M.Key_repr.t list;
      notify : M.Notify.t;
    }

    let create state = { state; running = []; notify = M.Notify.create () }
    let get_state t = t.state

    let rec block_k t k f =
      let repr = M.key_repr_of_key k in
      if CCList.mem ~eq:M.Key_repr.equal repr t.running then
        let open M.C in
        M.Notify.wait t.notify >>= fun () -> block_k t k f
      else
        let open M.C in
        t.running <- repr :: t.running;
        protect f
        >>= fun ret ->
        t.running <- CCList.remove ~eq:M.Key_repr.equal ~key:repr t.running;
        M.Notify.notify t.notify >>= fun () -> ret
  end

  let build rebuilder tasks k st =
    let rec fetch : 'r. 'r M.k -> 'r M.C.t =
     fun k ->
      let open M.C in
      tasks.Tasks.get (St.get_state st) k
      >>= function
      | None -> M.State.get_k (St.get_state st) k
      | Some task ->
          St.block_k st k (fun () ->
              M.State.get_k_opt (St.get_state st) k
              >>= function
              | Some v -> (
                  rebuilder.Rebuilder.run (St.get_state st) k v
                  >>= function
                  | true ->
                      task (St.get_state st) { Fetcher.fetch }
                      >>= fun v -> M.State.set_k (St.get_state st) k v >>= fun () -> return v
                  | false -> return v)
              | None ->
                  task (St.get_state st) { Fetcher.fetch }
                  >>= fun v -> M.State.set_k (St.get_state st) k v >>= fun () -> return v)
    in
    fetch k
end

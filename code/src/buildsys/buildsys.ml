module Error = struct
  type key_repr = string [@@deriving show]

  type t = {
    blocking : (key_repr * key_repr list) list;
    cycle : key_repr list;
    k : key_repr;
    path : key_repr list;
    running : (key_repr * key_repr list) list;
  }
  [@@deriving show]

  exception Fetch_cycle_exn of t
end

module type S = sig
  module Key_repr : sig
    type t

    val equal : t -> t -> bool
    val to_string : t -> string
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
  type key_repr
  type 'a c
  type state

  module Fetcher : sig
    type t = { fetch : 'r. 'r k -> 'r c }
  end

  module Task : sig
    type 'v t = key_repr list -> state -> Fetcher.t -> 'v c
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
  T
    with type 'a k = 'a M.k
     and type key_repr = M.Key_repr.t
     and type 'a c = 'a M.C.t
     and type state = M.State.t = struct
  type 'a k = 'a M.k
  type key_repr = M.Key_repr.t
  type 'a c = 'a M.C.t
  type state = M.State.t

  module Fetcher = struct
    type t = { fetch : 'r. 'r M.k -> 'r M.C.t }
  end

  module Task = struct
    type 'v t = M.Key_repr.t list -> M.State.t -> Fetcher.t -> 'v M.C.t
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
      mutable running : (M.Key_repr.t * M.Key_repr.t list) list;
      mutable blocking : (M.Key_repr.t * M.Key_repr.t list) list;
      notify : M.Notify.t;
    }

    let create state = { state; running = []; blocking = []; notify = M.Notify.create () }
    let get_state t = t.state

    let assert_no_cycle k path t =
      let running = t.running in
      let blocking = t.blocking in
      let topo =
        CCList.filter_map
          (fun (_, p) ->
            match CCList.rev p with
            | k :: vs -> Some (k, vs)
            | [] -> None)
          ((k, path) :: blocking)
      in
      match Tsort.sort topo with
      | Tsort.Sorted _ -> ()
      | Tsort.ErrorCycle cycle ->
          raise
            (Error.Fetch_cycle_exn
               {
                 Error.blocking =
                   CCList.map
                     (fun (k, p) -> (M.Key_repr.to_string k, CCList.map M.Key_repr.to_string p))
                     blocking;
                 cycle = CCList.map M.Key_repr.to_string cycle;
                 k = M.Key_repr.to_string k;
                 path = CCList.map M.Key_repr.to_string path;
                 running =
                   CCList.map
                     (fun (k, p) -> (M.Key_repr.to_string k, CCList.map M.Key_repr.to_string p))
                     running;
               })

    let rec block_k path t k f =
      let repr = M.key_repr_of_key k in
      if CCList.mem ~eq:(fun (k1, _) (k2, _) -> M.Key_repr.equal k1 k2) (repr, path) t.running then (
        let open M.C in
        t.blocking <- (repr, path) :: t.blocking;
        assert_no_cycle repr path t;
        M.Notify.wait t.notify
        >>= fun () ->
        t.blocking <-
          CCList.remove
            ~eq:(fun (k1, _) (k2, _) -> M.Key_repr.equal k1 k2)
            ~key:(repr, path)
            t.blocking;
        block_k path t k f)
      else
        let open M.C in
        t.running <- (repr, path) :: t.running;
        protect f
        >>= fun ret ->
        t.running <-
          CCList.remove
            ~eq:(fun (k1, _) (k2, _) -> M.Key_repr.equal k1 k2)
            ~key:(repr, path)
            t.running;
        M.Notify.notify t.notify >>= fun () -> ret
  end

  let build rebuilder tasks k st =
    let rec fetch : 'r. M.Key_repr.t list -> 'r M.k -> 'r M.C.t =
     fun path k ->
      let open M.C in
      let path = path @ [ M.key_repr_of_key k ] in
      tasks.Tasks.get (St.get_state st) k
      >>= function
      | None -> M.State.get_k (St.get_state st) k
      | Some task ->
          St.block_k path st k (fun () ->
              M.State.get_k_opt (St.get_state st) k
              >>= function
              | Some v -> (
                  rebuilder.Rebuilder.run (St.get_state st) k v
                  >>= function
                  | true ->
                      task path (St.get_state st) { Fetcher.fetch = (fun k -> fetch path k) }
                      >>= fun v -> M.State.set_k (St.get_state st) k v >>= fun () -> return v
                  | false -> return v)
              | None ->
                  task path (St.get_state st) { Fetcher.fetch = (fun k -> fetch path k) }
                  >>= fun v -> M.State.set_k (St.get_state st) k v >>= fun () -> return v)
    in
    fetch [] k
end

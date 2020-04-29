(* TODO Reduce extra pattern matching, for example set to determine.

   TODO Reduce amount of duplication in abort/abort_exn/cancel.

   TODO Try to reduce number of allocations.

   TODO Refactor so the Exec_queue is part of state rather than global. *)
module List = ListLabels

(** This documentation contains implementation details that are useful for
    understanding how it works.  Please see [abb_fut.mli] for the actual
    interface. *)
module State = struct
  type t = unit

  let create () = ()
end

let max_ops = 20

module Watchers = struct
  type 'a watcher = ('a Abb_intf.Future.Set.t -> State.t -> State.t) option ref

  type 'a t = 'a watcher list

  let add watcher t = watcher :: t

  let union = ( @ )

  let gc t = List.filter ~f:(fun w -> !w <> None) t
end

module Exec_queue : sig
  val exec : 'a Watchers.t -> 'a Abb_intf.Future.Set.t -> State.t -> State.t
end = struct
  type t = Exec : ('a Watchers.t * 'a Abb_intf.Future.Set.t) -> t

  let executing = ref false

  let queue : t Queue.t = Queue.create ()

  let rec loop s =
    if not (Queue.is_empty queue) then
      let (Exec (watchers, v)) = Queue.pop queue in
      let s =
        List.fold_left
          ~f:(fun s watcher ->
            match !watcher with
              | Some w -> w v s
              | None   -> s)
          ~init:s
          watchers
      in
      loop s
    else
      s

  let exec watchers v s =
    Queue.add (Exec (watchers, v)) queue;
    if !executing then
      s
    else (
      executing := true;
      let s = loop s in
      executing := false;
      s
    )
end

(** A future contains a mutable state value, which will be updated as the
    future changes state.  Determined futures will contain the determined
    value, or if it has been aborted.

    An undetermined future contains a list of functions to call when it
    becomes determined, called watchers.  It optionally contains a function to
    execute in order to kick off any work that needs to happen in order to
    determine it.

    Getting the value of a future requires binding to it, which takes a future,
    [t], and a function to be called once the the future is determined, [f] and
    returns a future which will evaluate to the value of the function.  The
    function, [f], takes a value of the type ['a] and returns a future of the
    type ['b t].

    In this implementation, if {!bind} is called on an already determined
    future, the corresponding function is immediately called.

    If {!bind} is given an undetermined future [t], an undetermined future,
    [fut] is created.  This future will be returned from {!bind}.  A watcher
    is created and added to the watchers of [t].  This watcher will execute
    the function [f] when [t] is determined.  The future returned by the
    application of [f] will become an alias to [fut].  That is, all of its
    watchers will be added to [fut]'s, and its value will be replaced by one
    linking to [fut].

    In this way, futures that are determined to a value will propagate the the
    determined value by applying it to its watchers.

    Futures also support aborts.  Aborting a future determines all watchers
    [`Aborted] as well those futures which the existing future depends on, and
    so on recursively.  Aborting a dependency is done by determining it to an
    abort token, calling its abort function, aborting all its watchers and its
    dependencies.

    In the case of monadic combinators, most futures will have one dependency.
    However in the case of applicative combinators this may not be the case.
    Consider a function, [both], which takes two futures and returns a new
    future which will evaluate to a tuple with the determined value of the two
    futures.  This future has two dependencies and aborting it will abort both.

    There are other combinators that will temporarily depend on another future,
    for example [first] takes two futures and creates a future which becomes
    determined when the first of the two futures becomes evaluated.

    The first combinator demonstrates another property, which is that watchers
    can be removes from a watch list.  In the case of [first], when the second
    future eventually becomes determined, it should not executed watcher
    associated with the, now determined, [first] future.  This is done by the
    watcher being a ref which is set to a dummy value when the watcher has been
    executed.
*)
type +'a t

type abort = unit -> unit t

type abort' =
  [ `Exn     of exn * Printexc.raw_backtrace option
  | `Aborted
  ]

type 'a u = { mutable state : 'a state }

and 'a state =
  [ 'a Abb_intf.Future.Set.t
  | `Undet of 'a undet
  | `Alias of 'a u
  ]

and 'a undet = {
  mutable watchers : 'a Watchers.t;
  mutable deps : dep list;
  abort : abort;
  mutable defer : ('a t -> 'a undet -> State.t -> State.t) option;
  mutable num_ops : int;
  self : self;
}

and dep = Dep : 'a u -> dep

and self = Self : 'a Watchers.watcher -> self

external t_of_u : 'a u -> 'a t = "%identity"

external u_of_t : 'a t -> 'a u = "%identity"

module Deps = struct
  type t = dep list

  let add dep t = dep :: t

  let union = ( @ )

  let gc t =
    (* Only keep the undetermined deps as those are the ones that can affect
       have an affect *)
    List.filter
      ~f:(function
        | Dep { state = `Undet _ } -> true
        | _                        -> false)
      t
end

let add_watcher t w =
  if t.num_ops > max_ops then (
    t.num_ops <- 0;
    t.watchers <- Watchers.gc t.watchers;
    t.deps <- Deps.gc t.deps
  );
  t.num_ops <- t.num_ops + 1;
  t.watchers <- Watchers.add w t.watchers

let return v = t_of_u { state = `Det v }

let noop_abort () = return ()

let undetermined ?defer s deps =
  { state = `Undet { watchers = []; abort = noop_abort; defer; deps; num_ops = 0; self = s } }

(* This should be modified to collapse down the alias if it's too long *)
let rec collapse_alias t =
  match t.state with
    | `Det _ | `Aborted | `Exn _ | `Undet _ -> t
    | `Alias t' -> collapse_alias t'

let determine u v =
  match u.state with
    | `Undet undet ->
        t_of_u
          (undetermined
             ~defer:(fun t und s ->
               u.state <- (v : 'a Abb_intf.Future.Set.t :> 'a state);
               let watchers = undet.watchers in
               let s = Exec_queue.exec watchers v s in
               let u = u_of_t t in
               u.state <- `Det ();
               let watchers = und.watchers in
               Exec_queue.exec watchers (`Det ()) s)
             (Self (ref None))
             [])
    | `Alias _     -> assert false
    | _            -> assert false

let run_with_state t s =
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | `Undet ({ defer = Some f; _ } as undet) ->
        undet.defer <- None;
        f (t_of_u u) undet s
    | `Undet _ | `Det _ | `Aborted | `Exn _ -> s
    | `Alias _ -> assert false

(* TODO Figure out how to make this generic to the [abort'] type. *)
let rec abort' : 'a. 'a u -> State.t -> State.t =
 fun u s ->
  let u = collapse_alias u in
  match u.state with
    | `Undet undet               ->
        u.state <- `Aborted;
        let abort_f = undet.abort in
        let watchers = undet.watchers in
        let deps = undet.deps in
        let s = run_with_state (abort_f ()) s in
        let s = Exec_queue.exec watchers `Aborted s in
        List.fold_left ~init:s ~f:(fun s (Dep u) -> abort' u s) deps
    | `Det _ | `Aborted | `Exn _ -> s
    | `Alias _                   -> assert false

let rec abort_exn' : 'a. 'a u -> exn * Printexc.raw_backtrace option -> State.t -> State.t =
 fun u exn s ->
  let u = collapse_alias u in
  match u.state with
    | `Undet undet               ->
        u.state <- `Exn exn;
        let abort_f = undet.abort in
        let watchers = undet.watchers in
        let deps = undet.deps in
        let s = run_with_state (abort_f ()) s in
        let s = Exec_queue.exec watchers (`Exn exn) s in
        List.fold_left ~init:s ~f:(fun s (Dep u) -> abort_exn' u exn s) deps
    | `Det _ | `Aborted | `Exn _ -> s
    | `Alias _                   -> assert false

let abort t =
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | `Undet undet               ->
        t_of_u
          (undetermined
             ~defer:(fun t _ s ->
               let s = abort' u s in
               (* TODO Make this not create a whole new deferred to determine this *)
               run_with_state (determine (u_of_t t) (`Det ())) s)
             (Self (ref None))
             [])
    | `Aborted | `Exn _ | `Det _ -> return ()
    | `Alias _                   -> assert false

let abort_exn t exn =
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | `Undet undet               ->
        t_of_u
          (undetermined
             ~defer:(fun t _ s ->
               let sp = abort_exn' u exn s in
               (* TODO Make this not create a whole new deferred to determine this *)
               run_with_state (determine (u_of_t t) (`Det ())) s)
             (Self (ref None))
             [])
    | `Aborted | `Exn _ | `Det _ -> return ()
    | `Alias _                   -> assert false

let cancel t =
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | `Undet undet               ->
        t_of_u
          (undetermined
             ~defer:(fun t _ s ->
               u.state <- `Aborted;
               let abort_f = undet.abort in
               let (Self w) = undet.self in
               w := None;
               let watchers = undet.watchers in
               let s = run_with_state (abort_f ()) s in

               (* TODO Verify this behaviour is correct.

                  This behaviour might actually be wrong.  This will cause the watchers to act
                  like regular aborts. *)
               let s = Exec_queue.exec watchers `Aborted s in
               run_with_state (determine (u_of_t t) (`Det ())) s)
             (Self (ref None))
             [])
    | `Aborted | `Exn _ | `Det _ -> return ()
    | `Alias _                   -> assert false

let add_dep ~dep t =
  let dep = u_of_t dep in
  let t = u_of_t t in
  match (collapse_alias t).state with
    | `Undet undet               -> undet.deps <- Deps.add (Dep dep) undet.deps
    | `Aborted | `Exn _ | `Det _ -> ()
    | `Alias _                   -> assert false

(** Aliasing takes a future and makes it an alias to another future. Generally
    one future is what a user is waiting on but it depends on a series of
    futures to become determined before finishing. As those dependencies keep
    on returning futures the internal one continually becomes an alias for
    that. *)
let alias (internal_fut, internal_state) (src, src_state) =
  internal_fut.state <- `Alias src;
  src_state.watchers <- Watchers.union internal_state.watchers src_state.watchers;
  src_state.deps <- Deps.union internal_state.deps src_state.deps

(** Apply a function to a future, [t], when it becomes determined.  If [t] is
    already determined, simply apply the function and return a determined
    future.  If [t] is not determined, then create a new undetermined future,
    [fut], is created and returned.  A [Watcher] is created and added to the
    watch list of [t], this watcher will apply the function to the determined
    value in [t] and determine [fut] with its result.

    The undetermined future has to be run so any work that needs to be
    executed in order to kick off the path to becoming determined. *)
let map : ('a -> 'b) -> 'a t -> 'b t =
 fun f t ->
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | `Det v                    -> return (f v)
    | (`Aborted | `Exn _) as st -> t_of_u { state = st }
    | `Undet undet              ->
        let w = ref None in
        let fut = undetermined ~defer:(fun _ _ -> run_with_state (t_of_u u)) (Self w) [ Dep u ] in
        let watcher st s =
          w := None;
          match st with
            | `Det v   -> (
                try run_with_state (determine fut (`Det (f v))) s
                with exn -> abort_exn' fut (exn, Some (Printexc.get_raw_backtrace ())) s )
            | `Aborted -> abort' fut s
            | `Exn exn -> abort_exn' fut exn s
        in
        w := Some watcher;
        add_watcher undet w;
        t_of_u fut
    | `Alias _                  -> assert false

(** Create a watcher which is watching on a future whose value will be another
   future then alias an internal future it.  So the parameter [fut] has the type
   ['a t] and this watcher is watching a future with the type ['a t t].  Again,
   any undetermined futures needs to be executed to kick off any work that will
   lead to them becoming determined.  Care also needs to be taken if either
   future is aborted. *)
let make_watcher fut st s =
  match st with
    | `Det t   -> (
        let u = collapse_alias (u_of_t t) in
        match (u.state, fut.state) with
          | ((`Det _ as v), `Undet _)     -> run_with_state (determine fut v) s
          | (`Undet us, `Undet fs)        ->
              (* Make our future an alias to the ts *)
              alias (fut, fs) (u, us);
              run_with_state (t_of_u u) s
          | (`Undet _, `Aborted)          -> abort' u s
          | (`Undet _, `Exn exn)          -> abort_exn' u exn s
          | (`Aborted, `Undet _)          -> abort' fut s
          | (`Exn exn, `Undet _)          -> abort_exn' fut exn s
          | (_, `Aborted) | (_, `Exn _)   -> s
          | (_, `Det _)                   -> assert false
          | (`Alias _, _) | (_, `Alias _) -> assert false )
    | `Aborted -> abort' fut s
    | `Exn exn -> abort_exn' fut exn s

(** Join takes a future of type ['a t t] and turns it into a future of type
    ['a t].  This makes implementing {!bind} in terms of {!map} easier. *)
let join : 'a t t -> 'a t =
 fun tt ->
  let u = collapse_alias (u_of_t tt) in
  match u.state with
    | `Det t                    -> (
        let u = collapse_alias (u_of_t t) in
        match u.state with
          | `Undet _ -> map (fun x -> x) (t_of_u u)
          | _        -> t )
    | (`Aborted | `Exn _) as st -> t_of_u { state = st }
    | `Undet undet              ->
        let w = ref None in
        let fut = undetermined ~defer:(fun _ _ -> run_with_state tt) (Self w) [ Dep u ] in
        let watcher = make_watcher fut in
        w := Some watcher;
        add_watcher undet w;
        t_of_u fut
    | `Alias _                  -> assert false

let bind : 'a t -> ('a -> 'b t) -> 'b t = fun t f -> join (map f t)

(** Each one needs to depend on the other for aborts to work properly.  If we
    have something like:

    {[ tuple <$> fut1 <*> fut2 ]}

    we need to make sure that if fut1 or fut2 is aborted, the whole thing
    aborts.  Because of applicatives, we can get cycles in between
    dependencies.

    TODO Guarantee all input futures begin executing concurrently. *)
let app ft t =
  add_dep ~dep:t ft;
  add_dep ~dep:ft t;
  join (map (fun v -> map (fun f -> f v) ft) t)

(** Often times it is valuable to let a future do what it needs to in order to
    make progress in becoming determined but not wait for it to happen.  For
    example, consider:

    {[
      let fut1 = read_socket socket1 in
      let fut2 = read_socket socket2 in
      fut1 >>= fun _ -> fut2 >>= fun _ -> do_something ]}

    The work associated with [fut2] may not be executed until [fut1] is
    determined because execution is not guaranteed to begin until the future
    is used in {!bind} or {!map}.  The latency of this execution will be the
    sum of performing [fut1] and [fut2].  In order to make sure both are
    executed concurrency, use [fork].

    {[
      let fut1 = read_socket socket1 in
      let fut2 = read_socket socket2 in
      fork fut1
      >>= fun () ->
      fork fut2
      >>= fun () ->
      fut1 >>= fun _ -> fut2 >>= fun _ -> do_something ]}

    Now the work associated with [fut1] and [fut2] are guaranteed the
    possibility of executing in parallel.  *)
let fork fut =
  t_of_u
    (undetermined
       ~defer:(fun t _ s ->
         let s = run_with_state fut s in
         run_with_state (determine (u_of_t t) (`Det ())) s)
       (Self (ref None))
       [])

let state t =
  let t = u_of_t t in
  match (collapse_alias t).state with
    | (`Det _ | `Aborted | `Exn _) as s -> s
    | `Undet _                          -> `Undet
    | `Alias _                          -> assert false

let await t =
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | (`Det _ | `Aborted | `Exn _) as s -> return s
    | `Undet undet                      ->
        let w = ref None in
        let fut = undetermined ~defer:(fun _ _ -> run_with_state (t_of_u u)) (Self w) [ Dep u ] in
        let watcher det s =
          w := None;
          match fut.state with
            | `Undet _                   -> run_with_state (determine fut (`Det det)) s
            | `Det _ | `Aborted | `Exn _ -> s
            | `Alias _                   -> assert false
        in
        w := Some watcher;
        add_watcher undet w;
        t_of_u fut
    | `Alias _                          -> assert false

(* TODO Determine if this actually needs to exist.  Just await should be fine.
   Something about being canceled or aborted? *)
let await_map f t =
  let u = collapse_alias (u_of_t t) in
  match u.state with
    | (`Det _ | `Exn _ | `Aborted) as v -> return (f v)
    | `Undet undet                      ->
        let w = ref None in
        let fut = undetermined ~defer:(fun _ _ -> run_with_state (t_of_u u)) (Self w) [ Dep u ] in
        let watcher det s =
          w := None;
          try run_with_state (determine fut (`Det (f det))) s
          with exn -> abort_exn' fut (exn, Some (Printexc.get_raw_backtrace ())) s
        in
        w := Some watcher;
        add_watcher undet w;
        t_of_u fut
    | `Alias _                          -> assert false

let await_bind f t = join (await_map f t)

module Infix_monad = struct
  let ( >>= ) t f = bind t f

  let ( >>| ) t f = map f t
end

module Infix_app = struct
  let ( <*> ) = app

  let ( <$> ) f v = return f <*> v
end

module Promise = struct
  type 'a fut = 'a t

  type 'a t = 'a fut

  let create ?(abort = noop_abort) () =
    let self = Self (ref None) in
    t_of_u { state = `Undet { watchers = []; abort; defer = None; deps = []; num_ops = 0; self } }

  external future : 'a t -> 'a fut = "%identity"

  let set t v =
    let u = collapse_alias (u_of_t t) in
    match u.state with
      | `Undet _                   -> determine u (`Det v)
      | `Det _ | `Aborted | `Exn _ -> return ()
      | `Alias _                   -> assert false

  let set_exn t exn =
    let u = collapse_alias (u_of_t t) in
    match u.state with
      | `Undet _                   -> determine u (`Exn exn)
      | `Det _ | `Aborted | `Exn _ -> return ()
      | `Alias _                   -> assert false
end

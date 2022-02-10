(* TODO: Try to reduce number of allocations. *)

module type S = sig
  type t
end

module State = struct
  type 'a t = {
    sched_state : 'a;
    max_ops : int;
  }

  let create sched_state = { sched_state; max_ops = 20 }
  let state t = t.sched_state
  let set_state sched_state t = { t with sched_state }
end

(* Needed to access State in the functor because there is another module in
   there called State *)
module State' = State

module Make (Sched_state : S) = struct
  module State = struct
    type t = Sched_state.t State.t
  end

  (* A Watcher is executed when a Future is determined with the value the future
     was determined to. *)
  module Watcher = struct
    type 'a t = (State.t -> 'a Abb_intf.Future.Set.t -> State.t) option ref

    let add w ws = w :: ws
    let concat ws ws' = ws @ ws'

    (* Execute a watcher if it is not None. *)
    let call w s v =
      match !w with
      | Some w -> w s v
      | None -> s

    (* Watchers can build up over time and some of them might have, for various
       reasons, been executed and set to None and they are referenced by
       non-determined futures.  So every once in awhile, clean up those watchers
       from a future.  It's not entirely clear if this is useful, yet, since the
       watcher being set to None doesn't use up much memory and this list will
       only really be walked once: when the future is determined. *)
    let gc ws =
      ListLabels.fold_left
        ~f:(fun acc w ->
          match !w with
          | Some _ -> w :: acc
          | None -> acc)
        ~init:[]
        ws
  end

  (* The type of a future.  This does not have a concrete definition because we
     are working around the compiler.  Are mutable but the semantics that we are
     implementing means that once a future becomes determined it is immutable.
     But there is no way to tell the compiler this, and since we want the future
     to support subtyping (the [+'a]), being mutable means the value stored must
     be invariant.  So, to get around this, we have this type without any
     definition and then we have the actual implementation type called ['a u],
     which is invariant, and we do a trick to go back and forth between [+'a t]
     and ['a u]. *)
  type +'a t
  type abort = unit -> unit t

  (* The concrete type of a future.  Future's are mutable, but once they are
     determined they become immutable.  A future has a state which starts as
     undetermined, can become determined or an alias.  An alias is a future that
     needs to exist because some unknown computation will eventually become its
     value, and once that computation is found out, we set the future to an
     alias to that future. *)
  type 'a u = { mutable state : 'a state }

  and 'a state =
    [ 'a Abb_intf.Future.Set.t
    | `Undet of 'a undet
    | `Alias of 'a u
    ]

  (* An undetermined has an optional function, which is some work to be
     executed, watchers are executed when this undetermined future becomes
     determined, deps are futures that are not required to be executed before
     this future is determined but in some meaningful way connected to it, the
     abort function is what to do if this future is aborted, and finally num_ops
     is how many operations have been performed on this future.  The definition
     of an "operation" is kind of vague but basically it corresponds to mutating
     this undetermined future in some way. *)
  and 'a undet = {
    mutable f : (State.t -> State.t) option;
    mutable watchers : 'a Watcher.t list;
    mutable deps : dep list;
    abort : abort;
    mutable num_ops : int;
  }

  (* A dependency can be any future and it will not have the same type as this
     future, so we have to hide the actual type in an existential so we can
     reference any future as a dependency. *)
  and dep = Dep : 'a u -> dep

  (* Some functions to scoot around the type system.  We can convert an 'a t to
     an 'a u and back using these. *)
  external t_of_u : 'a u -> 'a t = "%identity"
  external u_of_t : 'a t -> 'a u = "%identity"

  let rec find_non_alias = function
    | { state = `Alias u } -> find_non_alias u
    | u -> u

  (* When we want to work with a future we want generally want to work with the
     actual future.  But a future can be an alias to another one, so this
     function allows one to get to the actual future if it is an alias.  If it
     is more than two levels deep then bubble it up so we don't have to keep on
     walking this long train of aliases. *)
  let collapse_alias = function
    | { state = `Alias { state = `Alias u' } } as u ->
        let u' = find_non_alias u' in
        u.state <- `Alias u';
        u'
    | { state = `Alias u } -> u
    | u -> u

  (* The list of dependencies can grow and grow for a long-lived future, but
     once those deps are evaluated then they are no longer needed.  The point of
     a dep is that for when aborting, so a determined dependency is not useful.
     On top of that, a determined dependency can hold on to large amounts of
     data, causing a memory leak.  So every now and then, it's useful to GC deps
     to free that data.*)
  let gc_deps deps =
    ListLabels.fold_left
      ~f:(fun acc (Dep u) ->
        let u = collapse_alias u in
        match u.state with
        | `Alias _ -> assert false
        | `Undet _ -> Dep u :: acc
        | `Det _ | `Aborted | `Exn _ -> acc)
      ~init:[]
      deps

  (* We GC watchers and deps when the number of operations done on an
     undetermined future is over some value. *)
  let maybe_gc max_ops undet =
    if undet.num_ops > max_ops then (
      undet.num_ops <- 0;
      undet.watchers <- Watcher.gc undet.watchers;
      undet.deps <- gc_deps undet.deps)

  let add_watcher undet w =
    undet.watchers <- Watcher.add w undet.watchers;
    undet.num_ops <- undet.num_ops + 1

  let concat_watchers undet ws =
    undet.watchers <- Watcher.concat ws undet.watchers;
    undet.num_ops <- undet.num_ops + 1

  let add_dep : 'd. 'a undet -> 'd u -> unit =
   fun undet d ->
    undet.deps <- Dep d :: undet.deps;
    undet.num_ops <- undet.num_ops + 1

  let concat_deps undet deps =
    undet.deps <- deps @ undet.deps;
    undet.num_ops <- undet.num_ops + 1

  let return v = t_of_u { state = `Det v }
  let noop_abort () = return ()

  let run_with_state_u u s =
    match u.state with
    | `Det _ | `Aborted | `Exn _ -> s
    | `Undet ({ f = Some f; _ } as u') ->
        u'.f <- None;
        f s
    | `Undet _ -> s
    | `Alias _ -> assert false

  let run_with_state t s =
    let u = collapse_alias (u_of_t t) in
    run_with_state_u u s

  let undetermined ?f ?(abort = noop_abort) ?(watchers = []) ?(deps = []) () =
    { state = `Undet { f; watchers; deps; abort; num_ops = 0 } }

  let safe_call_abort undet s =
    try (run_with_state (undet.abort ()) s, `Aborted)
    with exn -> (s, `Exn (exn, Some (Printexc.get_raw_backtrace ())))

  let set' undet v s =
    let st = `Det v in
    ListLabels.fold_left ~f:(fun s w -> Watcher.call w s st) ~init:s undet.watchers

  let cancel' undet s =
    let s, det = safe_call_abort undet s in
    ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s undet.watchers

  let rec abort' : 'a. 'a undet -> State.t -> State.t =
   fun undet s ->
    let s =
      ListLabels.fold_left
        ~f:(fun s (Dep u) ->
          let u = collapse_alias u in
          match u.state with
          | `Alias _ -> assert false
          | `Undet undet ->
              u.state <- `Aborted;
              abort' undet s
          | `Aborted | `Exn _ | `Det _ -> s)
        ~init:s
        undet.deps
    in
    let s, det = safe_call_abort undet s in
    ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s undet.watchers

  let rec abort_exn' : 'a. 'a undet -> exn * Printexc.raw_backtrace option -> State.t -> State.t =
   fun undet exn s ->
    let s, st =
      match safe_call_abort undet s with
      | s, `Aborted -> (s, `Exn exn)
      | s, st -> (s, st)
    in
    let s = ListLabels.fold_left ~f:(fun s w -> Watcher.call w s st) ~init:s undet.watchers in
    ListLabels.fold_left
      ~f:(fun s (Dep u) ->
        let u = collapse_alias u in
        match u.state with
        | `Alias _ -> assert false
        | `Undet undet ->
            u.state <- st;
            abort_exn' undet exn s
        | `Aborted | `Exn _ | `Det _ -> s)
      ~init:s
      undet.deps

  let safe_apply u undet f v s =
    try
      let v = f v in
      u.state <- `Det v;
      set' undet v s
    with exn ->
      let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
      u.state <- `Exn exn';
      abort_exn' undet exn' s

  let add_dep ~dep t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Undet undet -> add_dep undet (u_of_t dep)
    | `Det _ | `Exn _ | `Aborted -> ()

  (* On join, we have [u], which is the future we have created that represents
     the incomplete computation, [v] which is the value of the completed
     computation, and [s] which is the state.

     The interesting case is when [u] is undetermined and [v] is a [`Det _]
     value.  If [v] is [`Det t], then [t] is another future which may or may not
     be determined.  Again, the interesting case for [t] is if it is
     undetermined.  In this case, we alias future [u] to the undetermined [t],
     we then combine their watchers and their dependencies and number of
     operations, and then we possibly perform a GC.

     At the end of the case described above, the future that was created during
     a [join] will now point to this future [t].  The situation this corresponds
     to the follow.

     Given this set of functions which return ['a t]:

     {[

     let f1 () = foo ()

     let f2 () = bar ()

     let f2 () = baz ()

     ]}

     And the following:

     {[ f1 () >>= fun () -> f2 >>= fun () -> f3 ]}

     The above will get translated to (

     {[ bind (f1 ()) (fun () -> bind f2 (fun () -> f3)) ]}

     Which then gets translated into:

     {[ join (map (fun () -> join (fun () -> f3) f2) (f1 ())) ]}

     The outer join is going to create a future that will evaluate whatever [f3]
     finally evaluates to.  Along the way, that future will keep on being
     updated as an alias to the various futures created along the way to
     evaluate f3. *)
  let join_watcher u v s =
    match (u.state, v) with
    | `Alias _, _ -> assert false
    | `Det _, _ -> assert false
    | `Aborted, _ | `Exn _, _ -> s
    | `Undet outer, `Aborted ->
        u.state <- `Aborted;
        abort' outer s
    | `Undet outer, `Exn exn ->
        u.state <- `Exn exn;
        abort_exn' outer exn s
    | `Undet outer, `Det t -> (
        let s = run_with_state t s in
        let u' = collapse_alias (u_of_t t) in
        match u'.state with
        | `Alias _ -> assert false
        | `Det v ->
            u.state <- `Det v;
            set' outer v s
        | `Aborted ->
            u.state <- `Aborted;
            abort' outer s
        | `Exn exn ->
            u.state <- `Exn exn;
            abort_exn' outer exn s
        | `Undet inner ->
            u.state <- `Alias u';
            concat_watchers inner outer.watchers;
            concat_deps inner outer.deps;
            inner.num_ops <- inner.num_ops + outer.num_ops;
            maybe_gc s.State'.max_ops inner;
            s)

  let join : 'a t t -> 'a t =
   fun t ->
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det t' -> t'
    | (`Aborted | `Exn _) as st -> t_of_u { state = st }
    | `Undet undet ->
        let u' = undetermined ~f:(run_with_state t) ~deps:[ Dep u ] () in
        let rec w =
          ref
            (Some
               (fun s v ->
                 w := None;
                 let u' = collapse_alias u' in
                 join_watcher u' v s))
        in
        add_watcher undet w;
        t_of_u u'

  let map : ('a -> 'b) -> 'a t -> 'b t =
   fun f t ->
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det v -> return (f v)
    | (`Aborted | `Exn _) as st -> t_of_u { state = st }
    | `Undet undet ->
        let u' = undetermined ~f:(run_with_state t) ~deps:[ Dep u ] () in
        let rec w =
          ref
            (Some
               (fun s v ->
                 w := None;
                 let u' = collapse_alias u' in
                 match u'.state with
                 | `Undet undet -> (
                     match v with
                     | `Det v -> safe_apply u' undet f v s
                     | `Aborted ->
                         u'.state <- `Aborted;
                         abort' undet s
                     | `Exn exn ->
                         u'.state <- `Exn exn;
                         abort_exn' undet exn s)
                 | `Aborted | `Exn _ -> s
                 | `Det _ -> assert false
                 | `Alias _ -> assert false))
        in
        add_watcher undet w;
        t_of_u u'

  let bind : 'a t -> ('a -> 'b t) -> 'b t = fun t f -> join (map f t)

  (* [fork] is needed to be concurrent.  We often want to let a future execute
     and then go do something else, so we need a function that lets a future
     evaluate but returns prior to it being finished. *)
  let fork t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det _ | `Aborted | `Exn _ -> return t
    | `Undet _ ->
        let rec u' =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        let u' = collapse_alias u' in
                        match u'.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Aborted | `Exn _ -> s
                        | `Undet undet ->
                            let s = run_with_state t s in
                            u'.state <- `Det t;
                            set' undet t s);
                  watchers = [];
                  deps = [];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u'

  let app_f_watcher u' f v s =
    match u'.state with
    | `Alias _ -> assert false
    | `Det _ -> assert false
    | `Aborted | `Exn _ -> s
    | `Undet undet -> (
        match f with
        | `Det f -> safe_apply u' undet f v s
        | `Aborted ->
            u'.state <- `Aborted;
            abort' undet s
        | `Exn exn ->
            u'.state <- `Exn exn;
            abort_exn' undet exn s)

  let app_v_watcher u' f v s =
    match u'.state with
    | `Alias _ -> assert false
    | `Det _ -> assert false
    | `Aborted | `Exn _ -> s
    | `Undet undet -> (
        match v with
        | `Det v -> safe_apply u' undet f v s
        | `Aborted ->
            u'.state <- `Aborted;
            abort' undet s
        | `Exn exn ->
            u'.state <- `Exn exn;
            abort_exn' undet exn s)

  let maybe_abort u u_undet u' v s =
    match v with
    | `Det _ -> s
    | `Exn exn -> (
        u.state <- `Exn exn;
        s
        |> abort_exn' u_undet exn
        |> fun s ->
        let u' = collapse_alias u' in
        match u'.state with
        | `Alias _ -> assert false
        | `Det _ | `Aborted | `Exn _ -> s
        | `Undet undet ->
            u'.state <- `Exn exn;
            abort_exn' undet exn s)
    | `Aborted -> (
        u.state <- `Aborted;
        s
        |> abort' u_undet
        |> fun s ->
        let u' = collapse_alias u' in
        match u'.state with
        | `Alias _ -> assert false
        | `Det _ | `Aborted | `Exn _ -> s
        | `Undet undet ->
            u'.state <- `Aborted;
            abort' undet s)

  (* Applicative implementation that ensures both futures are executing
     concurrently.  The implementation is rather annoying and requires a bunch
     of boilerplate because of the asynchronous nature.  There are three futures
     involved: the one created which will be the end result, the one for the
     function that will be applied, and finally the future whose value will be
     applied to the function.  All of these can fail and [ft] and [t] can be
     determined at different times and in different orders. *)
  let app ft t =
    let fu = collapse_alias (u_of_t ft) in
    let u = collapse_alias (u_of_t t) in
    match (fu.state, u.state) with
    | `Alias _, _ | _, `Alias _ -> assert false
    | `Det f, `Det v -> (
        try return (f v)
        with exn ->
          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
          t_of_u { state = `Exn exn' })
    | _ ->
        let rec u' =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        let s = run_with_state ft s in
                        let s = run_with_state t s in
                        let u' = collapse_alias u' in
                        let fu = collapse_alias (u_of_t ft) in
                        let u = collapse_alias (u_of_t t) in
                        match (u'.state, fu.state, u.state) with
                        | `Alias _, _, _ | _, `Alias _, _ | _, _, `Alias _ -> assert false
                        | `Undet undet, `Aborted, _ | `Undet undet, _, `Aborted ->
                            u'.state <- `Aborted;
                            abort' undet s
                        | `Undet undet, `Exn exn, _ | `Undet undet, _, `Exn exn ->
                            u'.state <- `Exn exn;
                            abort_exn' undet exn s
                        | `Undet undet, `Det f, `Det v -> safe_apply u' undet f v s
                        | `Undet _, `Undet f_undet, `Det v ->
                            let rec w =
                              ref
                                (Some
                                   (fun s f ->
                                     w := None;
                                     let u' = collapse_alias u' in
                                     app_f_watcher u' f v s))
                            in
                            add_watcher f_undet w;
                            s
                        | `Undet _, `Det f, `Undet v_undet ->
                            let rec w =
                              ref
                                (Some
                                   (fun s v ->
                                     w := None;
                                     let u' = collapse_alias u' in
                                     app_v_watcher u' f v s))
                            in
                            add_watcher v_undet w;
                            s
                        | `Undet _, `Undet f_undet, `Undet v_undet ->
                            let rec w_f =
                              ref
                                (Some
                                   (fun s f ->
                                     w_f := None;
                                     let u = collapse_alias u in
                                     let u' = collapse_alias u' in
                                     match u.state with
                                     | `Alias _ -> assert false
                                     | `Undet undet -> maybe_abort u undet u' f s
                                     | `Aborted | `Exn _ -> s
                                     | `Det v -> app_f_watcher u' f v s))
                            and w_v =
                              ref
                                (Some
                                   (fun s v ->
                                     w_v := None;
                                     let fu = collapse_alias fu in
                                     let u' = collapse_alias u' in
                                     match fu.state with
                                     | `Alias _ -> assert false
                                     | `Undet undet -> maybe_abort fu undet u' v s
                                     | `Aborted | `Exn _ -> s
                                     | `Det f -> app_v_watcher u' f v s))
                            in
                            add_watcher f_undet w_f;
                            add_watcher v_undet w_v;
                            s
                        | `Det _, _, _ | `Aborted, _, _ | `Exn _, _, _ -> s);
                  watchers = [];
                  deps = [ Dep (u_of_t ft); Dep (u_of_t t) ];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u'

  let state t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Undet _ -> `Undet
    | (`Det _ | `Aborted | `Exn _) as st -> st

  let await_map : ('a Abb_intf.Future.Set.t -> 'b) -> 'a t -> 'b t =
   fun f t ->
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | (`Det _ | `Exn _ | `Aborted) as v -> (
        try return (f v)
        with exn ->
          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
          t_of_u { state = `Exn exn' })
    | `Undet undet ->
        let rec w =
          ref
            (Some
               (fun s v ->
                 w := None;
                 let s = run_with_state t s in
                 let u' = collapse_alias u' in
                 match u'.state with
                 | `Alias _ -> assert false
                 | `Det _ -> assert false
                 | `Undet undet -> safe_apply u' undet f v s
                 | `Aborted | `Exn _ -> s))
        and u' =
          {
            state =
              `Undet
                {
                  f = Some (run_with_state t);
                  deps = [ Dep u ];
                  watchers = [];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        add_watcher undet w;
        t_of_u u'

  let await t = await_map (fun v -> v) t
  let await_bind f t = join (await_map f t)

  let abort t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det _ | `Aborted | `Exn _ -> return ()
    | `Undet _ ->
        let rec u =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        let u' = collapse_alias (u_of_t t) in
                        let s =
                          match u'.state with
                          | `Alias _ -> assert false
                          | `Undet undet ->
                              u'.state <- `Aborted;
                              abort' undet s
                          | `Det _ | `Exn _ | `Aborted -> s
                        in
                        let u = collapse_alias u in
                        match u.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Exn _ | `Aborted -> s
                        | `Undet undet ->
                            u.state <- `Det ();
                            set' undet () s);
                  watchers = [];
                  deps = [];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u

  let cancel t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det _ | `Aborted | `Exn _ -> return ()
    | `Undet _ ->
        let rec u =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        let u' = collapse_alias (u_of_t t) in
                        let s =
                          match u'.state with
                          | `Alias _ -> assert false
                          | `Det _ | `Exn _ | `Aborted -> s
                          | `Undet undet ->
                              u'.state <- `Aborted;
                              cancel' undet s
                        in
                        let u = collapse_alias u in
                        match u.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Exn _ | `Aborted -> s
                        | `Undet undet ->
                            u.state <- `Det ();
                            set' undet () s);
                  watchers = [];
                  deps = [];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u

  module Promise = struct
    type 'a fut = 'a t
    type 'a t = 'a fut

    let create ?abort () = t_of_u (undetermined ?abort ())

    external future : 'a t -> 'a fut = "%identity"

    let set t v =
      let rec u =
        {
          state =
            `Undet
              {
                f =
                  Some
                    (fun s ->
                      let u' = collapse_alias (u_of_t t) in
                      let s =
                        match u'.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Exn _ | `Aborted -> s
                        | `Undet undet ->
                            u'.state <- `Det v;
                            set' undet v s
                      in

                      let u = collapse_alias u in
                      match u.state with
                      | `Alias _ -> assert false
                      | `Det _ | `Exn _ | `Aborted -> s
                      | `Undet undet ->
                          u.state <- `Det ();
                          set' undet () s);
                watchers = [];
                deps = [];
                abort = noop_abort;
                num_ops = 0;
              };
        }
      in
      t_of_u u

    let set_exn t exn =
      let rec u =
        {
          state =
            `Undet
              {
                f =
                  Some
                    (fun s ->
                      let u' = collapse_alias (u_of_t t) in
                      let s =
                        match u'.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Exn _ | `Aborted -> s
                        | `Undet undet ->
                            u'.state <- `Exn exn;
                            abort_exn' undet exn s
                      in

                      let u = collapse_alias u in
                      match u.state with
                      | `Alias _ -> assert false
                      | `Det _ | `Exn _ | `Aborted -> s
                      | `Undet undet ->
                          u.state <- `Det ();
                          set' undet () s);
                watchers = [];
                deps = [];
                abort = noop_abort;
                num_ops = 0;
              };
        }
      in
      t_of_u u
  end

  module Infix_monad = struct
    let ( >>= ) = bind
    let ( >>| ) t f = map f t
  end

  module Infix_app = struct
    let ( <*> ) = app
    let ( <$> ) f v = return f <*> v
  end

  (* Provides access to the user state that is being threaded through the monad.
     The new state is returned and the a future that the whole thing evaluates
     to. *)
  let with_state f =
    let rec u =
      {
        state =
          `Undet
            {
              f =
                Some
                  (fun s ->
                    let u = collapse_alias u in
                    match u.state with
                    | `Alias _ -> assert false
                    | `Det _ | `Aborted | `Exn _ -> s
                    | `Undet undet -> (
                        try
                          let s, fut = f s in
                          u.state <- `Det fut;
                          set' undet fut s
                        with exn ->
                          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
                          u.state <- `Exn exn';
                          abort_exn' undet exn' s));
              watchers = [];
              deps = [];
              abort = noop_abort;
              num_ops = 0;
            };
      }
    in
    join (t_of_u u)
end

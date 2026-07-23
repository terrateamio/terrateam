(* Future / promise engine.

   {b Representation.}  A future ['a u] is a tiny mutable cell holding a state.
   Determined futures (Det / Aborted / Exn) carry just the value; only undet
   futures need to track the chain's [Sched_state.data], so [data] lives on
   ['a undet], not on every ['a u].

   {b Chain data.}  The chain's currently-active [Sched_state.data] is held in
   a per-domain DLS slot.  Watchers install it on entry via [with_chain_data]
   so when an awaiter resumes after a parked promise resolves, it sees the
   data its own chain set, not the producer's.  [set_data v] uses a special
   [`Det_with_data] state that triggers an install when downstream binds run
   the continuation.

   {b Debug build (ABB_FUT_DEBUG).}  This file is preprocessed by [cppo]; the
   blocks under [#if ABB_FUT_DEBUG = 1] add a per-[State] cross-domain race
   detector, and are stripped entirely in release builds (zero runtime cost,
   no atomic, no extra fields).

   The detector enforces Abb_fut's foundational invariant: at most one domain
   may drive a given [State.t] at a time.  Each [State.t] carries an [owner]
   atomic (and a unique [id] for diagnostics).  Every public [run_with_state]
   call CAS-claims the owner on entry and releases on exit; re-entrant calls
   from the same domain are allowed (the scheduler does this through nested
   binds and abort traversal).  If another domain is observed as the current
   owner, the process eprintfs a full diagnostic — state id, both domain ids,
   the chain-data slot (formatted via [set_debug_data_pp] if a printer was
   registered), and a 64-frame backtrace — then [Stdlib.exit 134].

   The flag is wired in [code/dune]: the [release] profile env-vars stanza
   forces [ABB_FUT_DEBUG=0]; the [dev] profile defaults to [1] but a shell
   [ABB_FUT_DEBUG=0] override disables it.  Schedulers that want richer
   diagnostics should call [Future.set_debug_data_pp] at startup to install
   a printer for their chain-data type (a no-op in release).  See
   [code/tests/abb_fut_debug] for the in-tree test that asserts the
   detector fires under dev.  *)

module type S = sig
  type t
  type data

  val zero_data : data
end

module State = struct
#if ABB_FUT_DEBUG = 1
  let next_id = Atomic.make 0
  let unowned = -1

  type 'a t = {
    sched_state : 'a;
    id : int;
    owner : int Atomic.t;
  }

  let create sched_state =
    {
      sched_state;
      id = Atomic.fetch_and_add next_id 1;
      owner = Atomic.make unowned;
    }

  let state t = t.sched_state
  let set_state sched_state t = { sched_state; id = t.id; owner = t.owner }
#else
  type 'a t = { sched_state : 'a }

  let create sched_state = { sched_state }
  let state t = t.sched_state
  let set_state sched_state _t = { sched_state }
#endif
end

(* The functor body needs the outer State module under a different name because
   it defines its own inner [State] alias. *)
module State' = State

module Make (Sched_state : S) = struct
  module State = struct
    type t = Sched_state.t State'.t
  end

  (* Per-domain "current chain data".  Bind installs it before invoking the
     continuation and watchers so [get_data] can read it directly.  Per-domain
     means cross-domain tasks are isolated. *)
  let chain_data_key = Domain.DLS.new_key (fun () -> Sched_state.zero_data)
  let get_chain_data () = Domain.DLS.get chain_data_key
  let set_chain_data d = Domain.DLS.set chain_data_key d
  let peek_chain_data = get_chain_data

  (* Save/set/restore around [thunk].  Skips work entirely on the hot path
     where data hasn't changed (physical equality), avoiding two DLS sets and
     the [try/with] frame.  Avoids [Fun.protect]'s closure allocation. *)
  let with_chain_data new_data thunk =
    let saved = get_chain_data () in
    if saved == new_data then thunk ()
    else (
      set_chain_data new_data;
      let r =
        try thunk ()
        with exn ->
          set_chain_data saved;
          raise exn
      in
      set_chain_data saved;
      r)

  (* A Watcher is a closure that runs when its target future is determined.
     It receives the inner state and the determined value (Det / Aborted /
     Exn) and returns the (possibly updated) state.

     Watchers are stored as [option ref] so they can be cancelled atomically
     by setting [w := None] without traversing the watcher list. *)
  module Watcher = struct
    type 'a t = (State.t -> 'a Abb_intf.Future.Set.t -> State.t) option ref

    let add w ws = w :: ws
    let concat ws ws' = ws @ ws'

    let call w s v =
      match !w with
      | Some w -> w s v
      | None -> s
  end

  (* The abstract future type.  Marked covariant for subtyping; internally
     ['a u] is invariant due to mutable [state], so we go through identity
     coercions. *)
  type +'a t
  type abort = unit -> unit t

  (* [data] on [`Det_with_data]: only set_data uses this — it's a marker that
     downstream binds should install [data] in DLS before evaluating the
     continuation.  Plain [`Det] carries no chain data; the chain's data
     comes from DLS or the awaiting undet's [data] field. *)
  type 'a state =
    [ `Det of 'a
    | `Det_with_data of 'a * Sched_state.data
    | `Aborted
    | `Exn of (exn * Printexc.raw_backtrace option[@opaque])
    | `Undet of 'a undet
    | `Alias of 'a u
    ]

  and 'a u = { mutable state : 'a state }

  (* [f] is "work to do when scheduled" — set for atomic futures (Promise.set,
     with_state, etc.) that mutate state on first run.  Composed futures
     (bind, map, app, await_map, fork) set [f] to drive their parent.

     There is no [data] field here: chain data lives only in the per-domain
     DLS slot, captured at watcher-attach time inside the watcher closure. *)
  and 'a undet = {
    mutable f : (State.t -> State.t) option;
    mutable watchers : 'a Watcher.t list;
    mutable deps : dep list;
    abort : abort;
    mutable num_ops : int;
  }

  and dep = Dep : 'a u -> dep

  external t_of_u : 'a u -> 'a t = "%identity"
  external u_of_t : 'a t -> 'a u = "%identity"

  (* Drop watchers whose closure has fired (set to None) and deps whose
     target is already determined.  The cost is a single O(N) walk on each
     trigger; we only fire it every [gc_threshold] mutations so the
     amortized cost is constant.  This is critical for long-running server
     loops where [hook_to]'s Undet/Undet aliasing keeps concatenating deps
     onto the next chain link — without GC they grow without bound. *)
  let gc_threshold = 32

  let gc_watchers ws =
    ListLabels.fold_left
      ~f:(fun acc w ->
        match !w with
        | Some _ -> w :: acc
        | None -> acc)
      ~init:[]
      ws

  let rec collapse_alias u =
    match u.state with
    | `Alias { state = `Alias u'; _ } ->
        let u' = collapse_alias u' in
        u.state <- `Alias u';
        u'
    | `Alias u' -> u'
    | _ -> u

  let gc_deps deps =
    ListLabels.fold_left
      ~f:(fun acc (Dep u) ->
        let u = collapse_alias u in
        match u.state with
        | `Alias _ -> assert false
        | `Undet _ -> Dep u :: acc
        | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> acc)
      ~init:[]
      deps

  let maybe_gc undet =
    if undet.num_ops > gc_threshold then (
      undet.num_ops <- 0;
      undet.watchers <- gc_watchers undet.watchers;
      undet.deps <- gc_deps undet.deps)

  let add_watcher undet w =
    undet.watchers <- Watcher.add w undet.watchers;
    undet.num_ops <- undet.num_ops + 1;
    maybe_gc undet

  let concat_watchers undet ws =
    undet.watchers <- Watcher.concat ws undet.watchers;
    undet.num_ops <- undet.num_ops + 1;
    maybe_gc undet

  let add_dep_undet : type a d. a undet -> d u -> unit =
   fun undet d ->
    undet.deps <- Dep d :: undet.deps;
    undet.num_ops <- undet.num_ops + 1;
    maybe_gc undet

  let return v = t_of_u { state = `Det v }
  let noop_abort () = return ()

  let undetermined ?f ?(abort = noop_abort) ?(watchers = []) ?(deps = []) () =
    { state = `Undet { f; watchers; deps; abort; num_ops = 0 } }

  (* Drive an undet's [f] once if present.  After running, [f] is cleared so
     it won't run again. *)
  let run_with_state_u u s =
    match u.state with
    | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
    | `Undet ({ f = Some f; _ } as u') ->
        u'.f <- None;
        f s
    | `Undet _ -> s
    | `Alias _ -> assert false

  let run_with_state_inner t s =
    let u = collapse_alias (u_of_t t) in
    run_with_state_u u s

#if ABB_FUT_DEBUG = 1
  (* Debug build: detect concurrent [run_with_state] on the same [State]
     from two different domains.  At most one domain may operate on a
     given State at a time; this is the foundational invariant of
     Abb_fut.  Re-entrant calls from the same domain are allowed (the
     scheduler does this through nested binds and abort traversal). *)

  let debug_data_pp : (Sched_state.data -> string) ref =
    ref (fun _ -> "<no chain-data printer registered>")

  let set_debug_data_pp f = debug_data_pp := f

  let report_cross_domain_race ~state ~owner ~me =
    let bt = Printexc.get_callstack 64 in
    let chain_str =
      try !debug_data_pp (peek_chain_data ())
      with exn -> Printf.sprintf "<chain-data printer raised: %s>" (Printexc.to_string exn)
    in
    Printf.eprintf
      "\n\
       ====================================================================\n\
       abb_fut: cross-domain access to a single State detected.\n\
       This is a fatal invariant violation — at most one domain may\n\
       drive a given State at a time.\n\
       --------------------------------------------------------------------\n\
       state.id           : %d\n\
       prior owner domain : %d\n\
       intruder domain    : %d (this domain, calling run_with_state now)\n\
       chain data         : %s\n\
       intruder backtrace :\n\
       %s\n\
       ====================================================================\n\
       %!"
      state.State'.id owner me chain_str (Printexc.raw_backtrace_to_string bt);
    Stdlib.exit 134

  let run_with_state t outer_s =
    let me = (Domain.self () :> int) in
    let rec claim () =
      let cur = Atomic.get outer_s.State'.owner in
      if cur = me then false
      else if cur = State'.unowned then
        if Atomic.compare_and_set outer_s.State'.owner State'.unowned me then true else claim ()
      else report_cross_domain_race ~state:outer_s ~owner:cur ~me
    in
    let claimed = claim () in
    let release () = if claimed then Atomic.set outer_s.State'.owner State'.unowned in
    match run_with_state_inner t outer_s with
    | r ->
        release ();
        r
    | exception e ->
        release ();
        raise e
#else
  let set_debug_data_pp _ = ()
  let run_with_state t outer_s = run_with_state_inner t outer_s
#endif

  let safe_call_abort undet s =
    try
      let t = undet.abort () in
      (run_with_state_inner t s, t, `Aborted)
    with exn -> (s, return (), `Exn (exn, Some (Printexc.get_raw_backtrace ())))

  let safe_call_abort_exn undet exn s =
    match safe_call_abort undet s with
    | s, t, `Aborted -> (s, t, `Exn exn)
    | s, t, exn -> (s, t, exn)

  (* Fire watchers with a determined value.  Each watcher's closure is
     responsible for installing chain data via [with_chain_data] before
     invoking user code. *)
  let set' undet v s =
    let st = `Det v in
    ListLabels.fold_left ~f:(fun s w -> Watcher.call w s st) ~init:s undet.watchers

  let watch_u_undet_state ~f s undet =
    let rec w =
      ref
        (Some
           (fun s _ ->
             w := None;
             f s))
    in
    add_watcher undet w;
    s

  let watch_u_state ~f s state =
    match state with
    | `Alias _ -> assert false
    | `Aborted | `Exn _ | `Det _ | `Det_with_data _ -> f s
    | `Undet undet -> watch_u_undet_state ~f s undet

  let watch_u ~f s u = watch_u_state ~f s (collapse_alias u).state

  (* Abort all deps depth-first, then this undet's [abort] runs.  We don't
     fire-and-forget the abort future — drive it like any other future to
     completion before continuing. *)
  let rec abort_deps : State.t -> dep list -> State.t * unit u =
   fun s deps ->
    let all_deps_complete = undetermined () in
    let num_deps = ref (List.length deps) in
    let f det watchers s =
      let s = ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s watchers in
      decr num_deps;
      if !num_deps > 0 then s
      else
        match all_deps_complete.state with
        | `Alias _ -> assert false
        | `Undet undet -> set' undet () s
        | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> assert false
    in
    let s =
      ListLabels.fold_left
        ~f:(fun s (Dep dep_u) ->
          let dep_u = collapse_alias dep_u in
          match dep_u.state with
          | `Alias _ -> assert false
          | `Undet undet -> (
              dep_u.state <- `Aborted;
              let s, abort_u = abort_deps s undet.deps in
              match abort_u.state with
              | `Alias _ -> assert false
              | `Aborted | `Exn _ -> assert false
              | `Det _ | `Det_with_data _ ->
                  let s, t, det = safe_call_abort undet s in
                  watch_u ~f:(f det undet.watchers) s (u_of_t t)
              | `Undet undet_abort_u ->
                  watch_u_undet_state
                    ~f:(fun s ->
                      let s, t, det = safe_call_abort undet s in
                      watch_u ~f:(f det undet.watchers) s (u_of_t t))
                    s
                    undet_abort_u)
          | `Aborted | `Exn _ | `Det _ | `Det_with_data _ ->
              decr num_deps;
              s)
        ~init:s
        deps
    in
    if !num_deps > 0 then (s, all_deps_complete) else (s, u_of_t (return ()))

  let abort' : 'a. 'a undet -> State.t -> State.t =
   fun undet s ->
    let s, u = abort_deps s undet.deps in
    watch_u
      ~f:(fun s ->
        let s, t, det = safe_call_abort undet s in
        watch_u
          ~f:(fun s ->
            ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s undet.watchers)
          s
          (u_of_t t))
      s
      u

  let rec abort_exn_deps :
      State.t -> exn * Printexc.raw_backtrace option -> dep list -> State.t * unit u =
   fun s exn deps ->
    let all_deps_complete = undetermined () in
    let num_deps = ref (List.length deps) in
    let f det watchers s =
      let s = ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s watchers in
      decr num_deps;
      if !num_deps > 0 then s
      else
        match all_deps_complete.state with
        | `Alias _ -> assert false
        | `Undet undet -> set' undet () s
        | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> assert false
    in
    let s =
      ListLabels.fold_left
        ~f:(fun s (Dep dep_u) ->
          let dep_u = collapse_alias dep_u in
          match dep_u.state with
          | `Alias _ -> assert false
          | `Undet undet -> (
              dep_u.state <- `Exn exn;
              let s, abort_u = abort_exn_deps s exn undet.deps in
              match abort_u.state with
              | `Alias _ -> assert false
              | `Aborted | `Exn _ -> assert false
              | `Det _ | `Det_with_data _ ->
                  let s, t, det = safe_call_abort_exn undet exn s in
                  watch_u ~f:(f det undet.watchers) s (u_of_t t)
              | `Undet undet_abort_u ->
                  watch_u_undet_state
                    ~f:(fun s ->
                      let s, t, det = safe_call_abort_exn undet exn s in
                      watch_u ~f:(f det undet.watchers) s (u_of_t t))
                    s
                    undet_abort_u)
          | `Aborted | `Exn _ | `Det _ | `Det_with_data _ ->
              decr num_deps;
              s)
        ~init:s
        deps
    in
    if !num_deps > 0 then (s, all_deps_complete) else (s, u_of_t (return ()))

  let abort_exn' : 'a. 'a undet -> exn * Printexc.raw_backtrace option -> State.t -> State.t =
   fun undet exn s ->
    let s, u = abort_exn_deps s exn undet.deps in
    watch_u
      ~f:(fun s ->
        let s, t, det = safe_call_abort_exn undet exn s in
        watch_u
          ~f:(fun s ->
            ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s undet.watchers)
          s
          (u_of_t t))
      s
      u

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
    | `Undet undet -> add_dep_undet undet (u_of_t dep)
    | `Det _ | `Det_with_data _ | `Exn _ | `Aborted -> ()

  (* ---- Bind / Map / Join ---- *)

  (* Hook a (possibly already-determined) [b] into [u_b] so that [u_b] mirrors
     [b]'s eventual outcome.  Used by [bind] and [map]'s Det shortcut paths. *)
  let hook_to u_b b s =
    let b = collapse_alias b in
    match (u_b.state, b.state) with
    | `Alias _, _ | _, `Alias _ -> assert false
    | (`Det _ | `Det_with_data _ | `Aborted | `Exn _), _ -> s
    | `Undet u_b_undet, `Det v ->
        u_b.state <- `Det v;
        set' u_b_undet v s
    | `Undet u_b_undet, `Det_with_data (v, _) ->
        u_b.state <- `Det v;
        set' u_b_undet v s
    | `Undet u_b_undet, `Aborted ->
        u_b.state <- `Aborted;
        abort' u_b_undet s
    | `Undet u_b_undet, `Exn exn ->
        u_b.state <- `Exn exn;
        abort_exn' u_b_undet exn s
    | `Undet u_b_undet, `Undet b_undet ->
        (* Alias u_b onto b: future references to u_b walk through to b.
           Move u_b's watchers and deps onto b so they fire / are aborted
           with b's resolution.  Drive b once so atomic [f]s (Promise.set,
           with_state, fork, ...) kick off.  In a recursive server loop
           [hook_to] is called every iteration; without [maybe_gc] here
           the merged deps list grows unboundedly. *)
        u_b.state <- `Alias b;
        concat_watchers b_undet u_b_undet.watchers;
        b_undet.deps <- u_b_undet.deps @ b_undet.deps;
        b_undet.num_ops <- b_undet.num_ops + u_b_undet.num_ops;
        maybe_gc b_undet;
        run_with_state_u b s

  (* Bind: the Det path runs the user's continuation eagerly with the
     parent's chain data installed (if any), and returns its result *directly*
     — no extra wrapper allocation.  The Undet path attaches a watcher on the
     parent and returns a fresh [u_b]. *)
  let bind : 'a t -> ('a -> 'b t) -> 'b t =
   fun t f ->
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det v -> (
        try f v
        with exn ->
          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
          t_of_u { state = `Exn exn' })
    | `Det_with_data (v, d) ->
        with_chain_data d (fun () ->
            try f v
            with exn ->
              let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
              t_of_u { state = `Exn exn' })
    | (`Aborted | `Exn _) as st -> t_of_u { state = st }
    | `Undet undet ->
        (* Capture the DLS at construction time (the awaiter's chain data),
           not parent.undet.data — the parent's data is the producer's, which
           is irrelevant to the awaiter. *)
        let captured = get_chain_data () in
        let u_b = undetermined ~f:(run_with_state_inner t) ~deps:[ Dep u ] () in
        let rec w =
          ref
            (Some
               (fun s v ->
                 w := None;
                 with_chain_data captured (fun () ->
                     match (u_b.state, v) with
                     | `Alias _, _ -> assert false
                     | (`Det _ | `Det_with_data _ | `Aborted | `Exn _), _ -> s
                     | `Undet u_b_undet, `Det v_a -> (
                         let b =
                           try Ok (u_of_t (f v_a))
                           with exn -> Error (exn, Some (Printexc.get_raw_backtrace ()))
                         in
                         match b with
                         | Error exn ->
                             u_b.state <- `Exn exn;
                             abort_exn' u_b_undet exn s
                         | Ok b -> hook_to u_b b s)
                     | `Undet u_b_undet, `Aborted ->
                         u_b.state <- `Aborted;
                         abort' u_b_undet s
                     | `Undet u_b_undet, `Exn exn ->
                         u_b.state <- `Exn exn;
                         abort_exn' u_b_undet exn s)))
        in
        add_watcher undet w;
        t_of_u u_b

  (* Map: like bind but the continuation returns a value, not a future. *)
  let map : ('a -> 'b) -> 'a t -> 'b t =
   fun f t ->
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det v -> (
        try t_of_u { state = `Det (f v) }
        with exn ->
          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
          t_of_u { state = `Exn exn' })
    | `Det_with_data (v, d) ->
        with_chain_data d (fun () ->
            try t_of_u { state = `Det (f v) }
            with exn ->
              let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
              t_of_u { state = `Exn exn' })
    | (`Aborted | `Exn _) as st -> t_of_u { state = st }
    | `Undet undet ->
        let captured = get_chain_data () in
        let u_b = undetermined ~f:(run_with_state_inner t) ~deps:[ Dep u ] () in
        let rec w =
          ref
            (Some
               (fun s v ->
                 w := None;
                 with_chain_data captured (fun () ->
                     match (u_b.state, v) with
                     | `Alias _, _ -> assert false
                     | (`Det _ | `Det_with_data _ | `Aborted | `Exn _), _ -> s
                     | `Undet u_b_undet, `Det v_a -> safe_apply u_b u_b_undet f v_a s
                     | `Undet u_b_undet, `Aborted ->
                         u_b.state <- `Aborted;
                         abort' u_b_undet s
                     | `Undet u_b_undet, `Exn exn ->
                         u_b.state <- `Exn exn;
                         abort_exn' u_b_undet exn s)))
        in
        add_watcher undet w;
        t_of_u u_b

  (* Join: flatten an ['a t t]. *)
  let join : 'a t t -> 'a t = fun t -> bind t (fun x -> x)

  (* ---- Fork ---- *)

  let fork t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> t_of_u { state = `Det t }
    | `Undet _ ->
        let rec u' =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        match u'.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
                        | `Undet undet ->
                            let s = run_with_state_inner t s in
                            u'.state <- `Det t;
                            set' undet t s);
                  watchers = [];
                  deps = [ Dep u ];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u'

  (* ---- Applicative ---- *)

  let app_v_then u_b u_b_undet f v s =
    match v with
    | `Det v -> safe_apply u_b u_b_undet f v s
    | `Aborted ->
        u_b.state <- `Aborted;
        abort' u_b_undet s
    | `Exn exn ->
        u_b.state <- `Exn exn;
        abort_exn' u_b_undet exn s

  let maybe_abort u u_undet u' v s =
    match v with
    | `Det _ -> s
    | `Exn exn ->
        u.state <- `Exn exn;
        let s =
          watch_u_undet_state
            ~f:(fun s ->
              let u' = collapse_alias u' in
              match u'.state with
              | `Alias _ -> assert false
              | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
              | `Undet undet ->
                  u'.state <- `Exn exn;
                  abort_exn' undet exn s)
            s
            u_undet
        in
        abort_exn' u_undet exn s
    | `Aborted ->
        u.state <- `Aborted;
        let s =
          watch_u_undet_state
            ~f:(fun s ->
              let u' = collapse_alias u' in
              match u'.state with
              | `Alias _ -> assert false
              | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
              | `Undet undet ->
                  u'.state <- `Aborted;
                  abort' undet s)
            s
            u_undet
        in
        abort' u_undet s

  let app ft t =
    let fu = collapse_alias (u_of_t ft) in
    let u = collapse_alias (u_of_t t) in
    let det_value u =
      match u.state with
      | `Det v -> Some v
      | `Det_with_data (v, _) -> Some v
      | _ -> None
    in
    match (det_value fu, det_value u) with
    | Some f, Some v -> (
        try t_of_u { state = `Det (f v) }
        with exn ->
          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
          t_of_u { state = `Exn exn' })
    | _ ->
        let captured = get_chain_data () in
        let rec u' =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        let s = run_with_state_inner ft s in
                        let s = run_with_state_inner t s in
                        let u' = collapse_alias u' in
                        let fu = collapse_alias (u_of_t ft) in
                        let u = collapse_alias (u_of_t t) in
                        match (u'.state, fu.state, u.state) with
                        | `Alias _, _, _ | _, `Alias _, _ | _, _, `Alias _ -> assert false
                        | `Undet undet, (`Aborted | `Det_with_data _), _
                          when fu.state = `Aborted || u.state = `Aborted ->
                            u'.state <- `Aborted;
                            abort' undet s
                        | `Undet undet, _, `Aborted ->
                            u'.state <- `Aborted;
                            abort' undet s
                        | `Undet undet, `Aborted, _ ->
                            u'.state <- `Aborted;
                            abort' undet s
                        | `Undet undet, `Exn exn, _ | `Undet undet, _, `Exn exn ->
                            u'.state <- `Exn exn;
                            abort_exn' undet exn s
                        | ( `Undet undet,
                            (`Det f | `Det_with_data (f, _)),
                            (`Det v | `Det_with_data (v, _)) ) -> safe_apply u' undet f v s
                        | `Undet _, `Undet f_undet, (`Det v | `Det_with_data (v, _)) ->
                            let rec w =
                              ref
                                (Some
                                   (fun s f_v ->
                                     w := None;
                                     with_chain_data captured (fun () ->
                                         match u'.state with
                                         | `Undet undet -> app_v_then u' undet (fun f -> f v) f_v s
                                         | _ -> s)))
                            in
                            add_watcher f_undet w;
                            s
                        | `Undet _, (`Det f | `Det_with_data (f, _)), `Undet v_undet ->
                            let rec w =
                              ref
                                (Some
                                   (fun s v_v ->
                                     w := None;
                                     with_chain_data captured (fun () ->
                                         match u'.state with
                                         | `Undet undet -> app_v_then u' undet f v_v s
                                         | _ -> s)))
                            in
                            add_watcher v_undet w;
                            s
                        | `Undet _, `Undet f_undet, `Undet v_undet ->
                            let rec w_f =
                              ref
                                (Some
                                   (fun s f_v ->
                                     w_f := None;
                                     with_chain_data captured (fun () ->
                                         let u = collapse_alias u in
                                         let u' = collapse_alias u' in
                                         match u.state with
                                         | `Alias _ -> assert false
                                         | `Undet u_undet -> (
                                             match u'.state with
                                             | `Undet _ -> maybe_abort u u_undet u' f_v s
                                             | _ -> s)
                                         | `Aborted | `Exn _ -> s
                                         | `Det v | `Det_with_data (v, _) -> (
                                             match u'.state with
                                             | `Undet u'_undet ->
                                                 app_v_then u' u'_undet (fun f -> f v) f_v s
                                             | _ -> s))))
                            and w_v =
                              ref
                                (Some
                                   (fun s v_v ->
                                     w_v := None;
                                     with_chain_data captured (fun () ->
                                         let fu = collapse_alias fu in
                                         let u' = collapse_alias u' in
                                         match fu.state with
                                         | `Alias _ -> assert false
                                         | `Undet fu_undet -> (
                                             match u'.state with
                                             | `Undet _ -> maybe_abort fu fu_undet u' v_v s
                                             | _ -> s)
                                         | `Aborted | `Exn _ -> s
                                         | `Det f | `Det_with_data (f, _) -> (
                                             match u'.state with
                                             | `Undet u'_undet -> app_v_then u' u'_undet f v_v s
                                             | _ -> s))))
                            in
                            add_watcher f_undet w_f;
                            add_watcher v_undet w_v;
                            s
                        | `Det _, _, _ | `Det_with_data _, _, _ | `Aborted, _, _ | `Exn _, _, _ -> s);
                  watchers = [];
                  deps = [ Dep (u_of_t ft); Dep (u_of_t t) ];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u'

  (* ---- State / Await ---- *)

  let state t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Undet _ -> `Undet
    | `Det v | `Det_with_data (v, _) -> `Det v
    | `Aborted -> `Aborted
    | `Exn exn -> `Exn exn

  let await_map : ('a Abb_intf.Future.Set.t -> 'b) -> 'a t -> 'b t =
   fun f t ->
    let u = collapse_alias (u_of_t t) in
    let det_set u : 'a Abb_intf.Future.Set.t option =
      match u.state with
      | `Det v -> Some (`Det v)
      | `Det_with_data (v, _) -> Some (`Det v)
      | `Aborted -> Some `Aborted
      | `Exn exn -> Some (`Exn exn)
      | _ -> None
    in
    match det_set u with
    | Some v -> (
        try t_of_u { state = `Det (f v) }
        with exn ->
          let exn' = (exn, Some (Printexc.get_raw_backtrace ())) in
          t_of_u { state = `Exn exn' })
    | None ->
        let captured = get_chain_data () in
        let u' =
          {
            state =
              `Undet
                {
                  f = Some (run_with_state_inner t);
                  watchers = [];
                  deps = [ Dep u ];
                  abort = (fun () -> return (ignore (f `Aborted)));
                  num_ops = 0;
                };
          }
        in
        let rec w =
          ref
            (Some
               (fun s v ->
                 w := None;
                 with_chain_data captured (fun () ->
                     let s = run_with_state_inner t s in
                     match u'.state with
                     | `Alias _ -> assert false
                     | `Det _ | `Det_with_data _ -> assert false
                     | `Undet undet -> safe_apply u' undet f v s
                     | `Aborted | `Exn _ -> s)))
        in
        (match u.state with
        | `Undet undet -> add_watcher undet w
        | _ -> assert false);
        t_of_u u'

  let await t = await_map (fun v -> v) t
  let await_bind f t = join (await_map f t)

  (* ---- Abort / Cancel ---- *)

  let abort t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> return ()
    | `Undet _ ->
        let rec u' =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        (* [t] may have been determined between [abort] being
                           called and being executed, so re-fetch. *)
                        let u = collapse_alias (u_of_t t) in
                        let s =
                          watch_u
                            ~f:(fun s ->
                              match u'.state with
                              | `Alias _ -> assert false
                              | `Det _ | `Det_with_data _ | `Exn _ | `Aborted -> s
                              | `Undet undet ->
                                  u'.state <- `Det ();
                                  set' undet () s)
                            s
                            u
                        in
                        match u.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
                        | `Undet undet ->
                            u.state <- `Aborted;
                            abort' undet s);
                  watchers = [];
                  deps = [];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u'

  let cancel' undet s =
    let s, t, det = safe_call_abort undet s in
    watch_u
      ~f:(fun s -> ListLabels.fold_left ~f:(fun s w -> Watcher.call w s det) ~init:s undet.watchers)
      s
      (u_of_t t)

  let cancel t =
    let u = collapse_alias (u_of_t t) in
    match u.state with
    | `Alias _ -> assert false
    | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> return ()
    | `Undet _ ->
        let rec u' =
          {
            state =
              `Undet
                {
                  f =
                    Some
                      (fun s ->
                        let u = collapse_alias (u_of_t t) in
                        let s =
                          watch_u
                            ~f:(fun s ->
                              match u'.state with
                              | `Alias _ -> assert false
                              | `Det _ | `Det_with_data _ | `Exn _ | `Aborted -> s
                              | `Undet undet ->
                                  u'.state <- `Det ();
                                  set' undet () s)
                            s
                            u
                        in
                        match u.state with
                        | `Alias _ -> assert false
                        | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
                        | `Undet undet ->
                            u.state <- `Aborted;
                            cancel' undet s);
                  watchers = [];
                  deps = [];
                  abort = noop_abort;
                  num_ops = 0;
                };
          }
        in
        t_of_u u'

  (* ---- Promise ---- *)

  module Promise = struct
    type 'a fut = 'a t
    type 'a t = 'a fut

    let create ?abort () =
      (* Wrap the user's abort callback so it runs with the chain data that
         was active when the promise was created.  Without this, the abort
         handler runs with the *aborter's* DLS instead of the aborted
         chain's. *)
      let abort =
        match abort with
        | None -> None
        | Some f ->
            let captured = get_chain_data () in
            Some (fun () -> with_chain_data captured (fun () -> f ()))
      in
      t_of_u (undetermined ?abort ())

    external future : 'a t -> 'a fut = "%identity"

    let set t v =
      let u = collapse_alias (u_of_t t) in
      match u.state with
      | `Alias _ -> assert false
      | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> return ()
      | `Undet _ ->
          let rec u' =
            {
              state =
                `Undet
                  {
                    f =
                      Some
                        (fun s ->
                          (* [t] may have been set between [set] being called
                             and executing; re-fetch. *)
                          let u = collapse_alias (u_of_t t) in
                          let s =
                            watch_u
                              ~f:(fun s ->
                                match u'.state with
                                | `Alias _ -> assert false
                                | `Det _ | `Det_with_data _ | `Exn _ | `Aborted -> s
                                | `Undet undet ->
                                    u'.state <- `Det ();
                                    set' undet () s)
                              s
                              u
                          in
                          match u.state with
                          | `Alias _ -> assert false
                          | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
                          | `Undet undet ->
                              u.state <- `Det v;
                              set' undet v s);
                    watchers = [];
                    deps = [];
                    abort = noop_abort;
                    num_ops = 0;
                  };
            }
          in
          t_of_u u'

    let set_exn t exn =
      let u = collapse_alias (u_of_t t) in
      match u.state with
      | `Alias _ -> assert false
      | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> return ()
      | `Undet _ ->
          let rec u' =
            {
              state =
                `Undet
                  {
                    f =
                      Some
                        (fun s ->
                          let u = collapse_alias (u_of_t t) in
                          let s =
                            watch_u
                              ~f:(fun s ->
                                match u'.state with
                                | `Alias _ -> assert false
                                | `Det _ | `Det_with_data _ | `Exn _ | `Aborted -> s
                                | `Undet undet ->
                                    u'.state <- `Det ();
                                    set' undet () s)
                              s
                              u
                          in
                          match u.state with
                          | `Alias _ -> assert false
                          | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
                          | `Undet undet ->
                              u.state <- `Exn exn;
                              abort_exn' undet exn s);
                    watchers = [];
                    deps = [];
                    abort = noop_abort;
                    num_ops = 0;
                  };
            }
          in
          t_of_u u'
  end

  module Infix_monad = struct
    let ( >>= ) = bind
    let ( >>| ) t f = map f t
  end

  module Infix_app = struct
    let ( <*> ) = app
    let ( <$> ) f v = return f <*> v
  end

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
                    | `Det _ | `Det_with_data _ | `Aborted | `Exn _ -> s
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

  (* [set_data v] is a determined unit future tagged with [v] in its state.
     When a downstream bind/map sees this state it installs [v] in DLS for the
     duration of the continuation, so [get_data] inside the chain reads [v]. *)
  let set_data v = t_of_u { state = `Det_with_data ((), v) }

  (* [get_data ()] reads the per-domain DLS slot eagerly and returns a Det
     future of that value.  Most callers invoke it from within a bind, where
     the surrounding bind has installed the correct chain data via
     [with_chain_data] before evaluating the continuation. *)
  let get_data () =
    let d = get_chain_data () in
    t_of_u { state = `Det d }
end

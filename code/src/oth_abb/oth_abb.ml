let src = Logs.Src.create "oth_abb"

module Logs = (val Logs.src_log src : Logs.LOG)

module type ASSERT = sig
  include Oth.ASSERT

  module Exit_code : sig
    val zero : Abb_intf.Process.Exit_code.t -> unit
    val non_zero : Abb_intf.Process.Exit_code.t -> unit
  end
end

(* Oth.ASSERT extended with the assertions that name an Abb_intf type.  Exit_code routes through
   Oth.Assert.false_ rather than raising directly, so the exception carrier stays private to oth --
   false_ returns 'a, which unifies with unit at each branch. *)
module Assert = struct
  (* The shared vocabulary comes from Oth.Assert rather than being redeclared, so the two spellings
     -- Oth.Assert.* in a synchronous test, Oth_abb.Assert.* in an async one -- are the same code. *)
  include Oth.Assert

  module Exit_code = struct
    let zero = function
      | Abb_intf.Process.Exit_code.Exited 0 -> ()
      | Abb_intf.Process.Exit_code.Exited rc ->
          Oth.Assert.false_ (Format.sprintf "Expected a zero return code, but got %d" rc)
      | Abb_intf.Process.Exit_code.Signaled _ ->
          Oth.Assert.false_ "Expected 'Exited', got 'Signaled'"
      | Abb_intf.Process.Exit_code.Stopped _ -> Oth.Assert.false_ "Expected 'Exited', got 'Stopped'"

    let non_zero = function
      | Abb_intf.Process.Exit_code.Exited 0 ->
          Oth.Assert.false_ "Expected a non-zero return code, but got zero"
      | Abb_intf.Process.Exit_code.Exited _ -> ()
      | Abb_intf.Process.Exit_code.Signaled _ ->
          Oth.Assert.false_ "Expected 'Exited', got 'Signaled'"
      | Abb_intf.Process.Exit_code.Stopped _ -> Oth.Assert.false_ "Expected 'Exited', got 'Stopped'"
  end
end

let default_slots () =
  Sys.getenv_opt "OTH_PARALLEL"
  |> CCOption.flat_map CCFun.(CCString.trim %> CCInt.of_string)
  |> CCOption.get_or ~default:1

module Make (Abb : Abb_intf.S) = struct
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  module Time_inst = struct
    let time () = Abb.Sys.time ()
    let monotonic () = Abb.Sys.monotonic ()
  end

  module Bounded_exec = Abb_bounded_executor.Make (Abb) (CCString) (Time_inst)

  module T : Oth.T with type 'a t = 'a Abb.Future.t and type state = Bounded_exec.t = struct
    type 'a t = 'a Abb.Future.t
    type state = Bounded_exec.t

    let return = Abb.Future.return
    let bind x f = Abb.Future.Infix_monad.(x >>= f)

    let catch f h =
      Abb.Future.await_bind
        (function
          | `Det v -> Abb.Future.return v
          | `Exn (e, bt) -> h (e, bt)
          | `Aborted ->
              Abb.Future.Infix_monad.(
                Abb.Future.abort (Abb.Future.return ()) >>= fun () -> assert false))
        (Fut_comb.guard f)

    let create_state () =
      let slots = default_slots () in
      Logs.info (fun m -> m "bounded_executor : create : slots=%d" slots);
      Bounded_exec.create ~slots ()

    let run_test exec ~name f =
      Logs.debug (fun m -> m "test : start : %s" name);
      Abb.Future.Infix_monad.(
        Bounded_exec.run ~name:[ name ] exec f
        >>= fun r ->
        Logs.debug (fun m -> m "test : end : %s" name);
        Abb.Future.return r)

    let parallel thunks = Fut_comb.all (CCList.map (fun f -> f ()) thunks)

    let run_suite f =
      match Abb.Scheduler.run_with_state f with
      | `Det () -> ()
      | `Aborted ->
          Logs.err (fun m -> m "test suite aborted");
          exit 1
      | `Exn (exn, bt_opt) ->
          Logs.err (fun m -> m "test suite failed: %s" (Printexc.to_string exn));
          CCOption.iter
            (fun bt -> Logs.err (fun m -> m "%s" (Printexc.raw_backtrace_to_string bt)))
            bt_opt;
          exit 1
  end

  include Oth.Make (T)

  (* Re-export of the toplevel Assert.  Exit_code does not depend on Abb, but a call site that
     writes [module Oth_abb = Oth_abb.Make (Abb)] shadows the library name and so cannot reach
     the toplevel module; re-exporting means both spellings resolve. *)
  module Assert = Assert

  let to_sync_test = CCFun.id
end

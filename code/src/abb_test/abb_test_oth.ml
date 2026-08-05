let parallelism () =
  match Sys.getenv_opt "OTH_PARALLEL" with
  | Some s -> ( try max 1 (int_of_string (CCString.trim s)) with Failure _ -> 1)
  | None -> 1

module Make (Abb : Abb_intf.S) = struct
  module Test = struct
    type t = Oth.Test.t
  end

  let parallel = Oth.parallel
  let serial = Oth.serial

  let thread_pool_size () =
    let parallelism = parallelism () in
    max 2 ((Domain.recommended_domain_count () - parallelism) / parallelism)

  let run_sched f =
    match Abb.Scheduler.run_with_state ~thread_pool_size:(thread_pool_size ()) (fun () -> f ()) with
    | `Det () -> ()
    | `Aborted -> Oth.Assert.false_ "abb_test_oth: unexpected value"
    | `Exn (exn, Some bt) -> Printexc.raise_with_backtrace exn bt
    | `Exn (exn, None) -> raise exn

  let test ?tags ?desc ~name f = Oth.test ?tags ?desc ~name (fun _ -> run_sched f)
end

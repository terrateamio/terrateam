module Make (Abb : Abb_intf.S) = struct
  module Test = struct
    type t = Oth.Test.t
  end

  let parallel = Oth.parallel
  let serial = Oth.serial
  let timeout _duration _test = failwith "nyi"

  let thread_pool_size () =
    let parallelism = Oth.parallelism () in
    max 2 ((Domain.recommended_domain_count () - parallelism) / parallelism)

  let run_sched f =
    match Abb.Scheduler.run_with_state ~thread_pool_size:(thread_pool_size ()) (fun () -> f ()) with
    | `Det () -> ()
    | `Aborted -> assert false
    | `Exn (exn, Some bt) -> Printexc.raise_with_backtrace exn bt
    | `Exn (exn, None) -> raise exn

  let test ?tags ?desc ~name f = Oth.test ?tags ?desc ~name (fun _state -> run_sched f)
  let result_test _f _state = failwith "nyi"
  let to_sync_test = CCFun.id
end
